"""Check real DD admission, guest isolation, and ticket rejection through a gateway."""
import argparse
import base64
import json
import os
import socket
import struct
import urllib.parse
import urllib.request


def read_exact(connection, length):
    output = bytearray()
    while len(output) < length:
        chunk = connection.recv(length - len(output))
        if not chunk:
            raise EOFError("DD closed before completing authentication")
        output.extend(chunk)
    return bytes(output)


def admit(base, token):
    url = urllib.parse.urlsplit(base)
    if url.scheme != "http":
        raise ValueError("Run this check against the local HTTP gateway")
    connection = socket.create_connection((url.hostname, url.port or 80), timeout=10)
    connection.settimeout(10)
    request = (
        f"GET {url.path.rstrip('/')}/ HTTP/1.1\r\n"
        f"Host: {url.netloc}\r\nOrigin: {url.scheme}://{url.netloc}\r\n"
        "Connection: Upgrade\r\nUpgrade: websocket\r\nSec-WebSocket-Version: 13\r\n"
        f"Sec-WebSocket-Key: {base64.b64encode(os.urandom(16)).decode()}\r\n\r\n"
    )
    try:
        connection.sendall(request.encode("ascii"))
        headers = b""
        while not headers.endswith(b"\r\n\r\n"):
            headers += read_exact(connection, 1)
            if len(headers) > 8192:
                raise ValueError("Oversized upgrade response")
        if not headers.startswith(b"HTTP/1.1 101 "):
            raise ValueError("Gateway did not upgrade the WebSocket")
        for _ in range(1000):
            opcode, size = read_exact(connection, 2)
            length = size & 127
            if length == 126:
                length = struct.unpack("!H", read_exact(connection, 2))[0]
            elif length == 127:
                length = struct.unpack("!Q", read_exact(connection, 8))[0]
            if size & 128 or length > 32 * 1024 * 1024:
                raise ValueError("Unexpected server frame")
            body = read_exact(connection, length)
            if opcode & 15 == 8:
                return None
            if opcode & 15 != 2 or len(body) < 2:
                continue
            message = struct.unpack("!H", body[:2])[0]
            if message == 0:
                return None
            if message != 26:
                continue
            if len(body) > 2:
                return body[2:].rstrip(b"\0").decode("ascii")
            payload = b"\0\x1a" + token.encode("ascii") + b"\0"
            mask = os.urandom(4)
            encoded = bytes(value ^ mask[index % 4] for index, value in enumerate(payload))
            connection.sendall(bytes([0x82, 0x80 | len(payload)]) + mask + encoded)
        raise ValueError("No authentication result")
    finally:
        connection.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("gateway")
    parser.add_argument("--connections", type=int, default=2)
    args = parser.parse_args()
    base = args.gateway.rstrip("/")
    guests = set()
    first_ticket = None
    for _ in range(args.connections):
        with urllib.request.urlopen(base + "/auth/key", timeout=10) as response:
            ticket = json.load(response)["key"]
        first_ticket = first_ticket or ticket
        guest = admit(base, ticket)
        assert guest and guest.startswith("Guest-"), "Valid ticket was rejected"
        assert guest not in guests, "Two sessions received the same guest identity"
        guests.add(guest)
    assert admit(base, first_ticket) is None, "A used ticket was accepted twice"
    assert admit(base, "dpweb-v1:" + "0" * 32) is None, "An unissued ticket was accepted"
    print(f"PASS: {len(guests)} distinct guests; replay and unissued tickets rejected")


if __name__ == "__main__":
    main()
