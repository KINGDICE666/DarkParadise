#define _GNU_SOURCE
#include <arpa/inet.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <link.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

/* Linux x86 adapter, pinned to the upstream 516.1682 ELF build below. */
static const unsigned char expected_build[] = {
    0xe9, 0xcd, 0xd7, 0xc7, 0x7f, 0x6c, 0xea, 0xc5, 0xc3, 0xac,
    0x42, 0xb6, 0xf5, 0x57, 0x4f, 0x38, 0x8a, 0x96, 0x9b, 0xde
};
static uintptr_t engine_base;
static int build_matches;
static const char *auth_socket;
static void (*original_key_message)(void *, void *);
static void *(*find_connection)(unsigned short);
static void (*complete_login)(signed char, const char *, unsigned short);
static void (*close_connection)(unsigned short, int, int);
static unsigned char (*connection_guard)(void *, int);
static char *(*copy_string)(const char *);
static void *(*lookup_string)(uint32_t);
static __thread const char *active_guest_seed;
static __thread struct { const char *text; } guest_seed_entry;

static void *guest_seed(uint32_t id) {
    if (!active_guest_seed) return lookup_string(id);
    guest_seed_entry.text = active_guest_seed;
    return &guest_seed_entry;
}

static int find_engine(struct dl_phdr_info *info, size_t size, void *data) {
    (void)size;
    (void)data;
    const char *name = strrchr(info->dlpi_name, '/');
    if (strcmp(name ? name + 1 : info->dlpi_name, "libbyond.so")) return 0;
    engine_base = info->dlpi_addr;
    for (unsigned i = 0; i < info->dlpi_phnum; ++i) {
        const ElfW(Phdr) *ph = &info->dlpi_phdr[i];
        if (ph->p_type != PT_NOTE) continue;
        const unsigned char *cursor = (void *)(engine_base + ph->p_vaddr);
        const unsigned char *end = cursor + ph->p_memsz;
        while (cursor + sizeof(ElfW(Nhdr)) <= end) {
            const ElfW(Nhdr) *note = (const void *)cursor;
            size_t names = (note->n_namesz + 3u) & ~3u;
            size_t descs = (note->n_descsz + 3u) & ~3u;
            if (sizeof(*note) + names + descs > (size_t)(end - cursor)) break;
            if (note->n_type == NT_GNU_BUILD_ID && note->n_namesz == 4 &&
                note->n_descsz == sizeof(expected_build) &&
                !memcmp(cursor + sizeof(*note), "GNU", 4) &&
                !memcmp(cursor + sizeof(*note) + names, expected_build, sizeof(expected_build))) {
                build_matches = 1;
            }
            cursor += sizeof(*note) + names + descs;
        }
    }
    return 1;
}

static int wait_fd(int fd, short events) {
    struct pollfd p = {.fd = fd, .events = events};
    return poll(&p, 1, 250) == 1 && (p.revents & events);
}

static int consume_ticket(const char *token, char guest[32], char address[46]) {
    struct sockaddr_un addr = {.sun_family = AF_UNIX};
    if (strlen(auth_socket) >= sizeof(addr.sun_path)) return 0;
    strcpy(addr.sun_path, auth_socket);
    int fd = socket(AF_UNIX, SOCK_STREAM | SOCK_NONBLOCK | SOCK_CLOEXEC, 0);
    if (fd < 0) return 0;
    int ok = 0;
    if (connect(fd, (void *)&addr, sizeof(addr)) < 0) {
        if (errno != EINPROGRESS || !wait_fd(fd, POLLOUT)) goto done;
        int error = 0;
        socklen_t size = sizeof(error);
        if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &error, &size) || error) goto done;
    }
    char request[64];
    int length = snprintf(request, sizeof(request), "%s\n", token);
    if (!wait_fd(fd, POLLOUT) || send(fd, request, length, MSG_NOSIGNAL) != length) goto done;
    char reply[128];
    size_t used = 0;
    while (used < sizeof(reply) - 1 && wait_fd(fd, POLLIN)) {
        ssize_t count = recv(fd, reply + used, sizeof(reply) - 1 - used, 0);
        if (count <= 0) break;
        used += (size_t)count;
        if (memchr(reply, '\n', used)) break;
    }
    reply[used] = 0;
    if (used < 13 || strncmp(reply, "OK Guest-", 9) || reply[used - 1] != '\n' || memchr(reply, '\n', used - 1)) goto done;
    reply[used - 1] = 0;
    char *space = strchr(reply + 9, ' ');
    if (!space || space == reply + 9 || space - (reply + 3) >= 32 || strlen(space + 1) >= 46) goto done;
    for (char *digit = reply + 9; digit < space; ++digit) if (*digit < '0' || *digit > '9') goto done;
    unsigned char packed_address[16];
    if (inet_pton(AF_INET, space + 1, packed_address) != 1 && inet_pton(AF_INET6, space + 1, packed_address) != 1) goto done;
    memcpy(guest, reply + 3, space - (reply + 3));
    guest[space - (reply + 3)] = 0;
    strcpy(address, space + 1);
    ok = 1;
done:
    close(fd);
    return ok;
}

static void key_message(void *client, void *message) {
    unsigned short id = *(unsigned short *)((char *)client + 0x55c);
    unsigned char *connection = find_connection(id);
    uint32_t length = *(uint32_t *)((char *)message + 4);
    const char *token = *(const char **)((char *)message + 12);
    if (!connection || !(connection[0x26] & 4) ||
        *(unsigned short *)(connection + 0x34) != 5 ||
        !token || length < 9 || memcmp(token, "dpweb-v1:", 9)) {
        original_key_message(client, message);
        return;
    }
    char guest[32];
    char address[46];
    int valid = length == 42 && token[41] == 0;
    for (unsigned i = 9; valid && i < 41; ++i) {
        valid = (token[i] >= '0' && token[i] <= '9') || (token[i] >= 'a' && token[i] <= 'f');
    }
    if (!valid || !consume_ticket(token, guest, address)) {
        fprintf(stderr, "[web-auth] guest ticket rejected\n");
        close_connection(id, 9, 0);
        return;
    }
    if (*(char **)(connection + 0x38)) {
        close_connection(id, 9, 0);
        return;
    }
    if (!connection_guard(connection, 0)) {
        fprintf(stderr, "[web-auth] connection state integrity check failed\n");
        close_connection(id, 8, 0);
        return;
    }
    *(char **)(connection + 0x38) = copy_string(guest);
    *(char **)(connection + 0x2f8) = copy_string(token);
    *(unsigned short *)(connection + 0x34) = 6;
    connection_guard(connection, 1);
    fprintf(stderr, "[web-auth] guest ticket accepted\n");
    fflush(stderr);
    active_guest_seed = guest;
    complete_login(1, guest, id);
    active_guest_seed = NULL;
}

static const char *install_adapter(const char *socket_path) {
    if (original_key_message) return !strcmp(auth_socket, socket_path) ? "ok" : "adapter is already configured";
    if (!socket_path || !*socket_path || strlen(socket_path) >= sizeof(((struct sockaddr_un *)0)->sun_path)) return "invalid auth socket path";
    dl_iterate_phdr(find_engine, NULL);
    const unsigned char preamble[] = {0x55, 0x89, 0xe5, 0x57, 0x56};
    const unsigned char seed_call[] = {0xe8, 0x9a, 0x09, 0xef, 0xff};
    unsigned char *target = (void *)(engine_base + 0x3f2b80);
    unsigned char *seed_target = (void *)(engine_base + 0x3f2101);
    if (sizeof(void *) != 4 || !engine_base || !build_matches || memcmp(target, preamble, 5) || memcmp(seed_target, seed_call, 5)) {
        return "unsupported BYOND binary (requires Linux x86 516.1682, build e9cdd7c77f6ceac5c3ac42b6f5574f388a969bde)";
    }
    unsigned char *trampoline = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (trampoline == MAP_FAILED) return "cannot allocate adapter trampoline";
    memcpy(trampoline, preamble, 5);
    trampoline[5] = 0xe9;
    *(int32_t *)(trampoline + 6) = (intptr_t)(target + 5) - (intptr_t)(trampoline + 10);
    if (mprotect(trampoline, 4096, PROT_READ | PROT_EXEC)) {
        munmap(trampoline, 4096);
        return "cannot protect adapter trampoline";
    }
    find_connection = (void *)(engine_base + 0x405c60);
    complete_login = (void *)(engine_base + 0x3f1e90);
    close_connection = (void *)(engine_base + 0x3412d0);
    connection_guard = (void *)(engine_base + 0x407e10);
    copy_string = (void *)(engine_base + 0x4aa440);
    lookup_string = (void *)(engine_base + 0x2e2aa0);
    long page_size = sysconf(_SC_PAGESIZE);
    void *page = (void *)((uintptr_t)target & ~((uintptr_t)page_size - 1));
    if (mprotect(page, page_size, PROT_READ | PROT_WRITE | PROT_EXEC)) {
        munmap(trampoline, 4096);
        return "cannot install native guest adapter";
    }
    auth_socket = strdup(socket_path);
    if (!auth_socket) _exit(78);
    original_key_message = (void *)trampoline;
    target[0] = 0xe9;
    *(int32_t *)(target + 1) = (intptr_t)key_message - (intptr_t)(target + 5);
    seed_target[0] = 0xe8;
    *(int32_t *)(seed_target + 1) = (intptr_t)guest_seed - (intptr_t)(seed_target + 5);
    if (mprotect(page, page_size, PROT_READ | PROT_EXEC)) _exit(78);
    fprintf(stderr, "[web-auth] local guest adapter enabled for BYOND 516.1682\n");
    return "ok";
}

const char *initialize(int argc, const char **argv) {
    if (argc != 1 || !argv) return "expected one auth socket path";
    return install_adapter(argv[0]);
}

__attribute__((constructor)) static void install(void) {
    const char *socket_path = getenv("DP_WEB_AUTH_SOCKET");
    if (!socket_path || !*socket_path) return;
    const char *result = install_adapter(socket_path);
    if (strcmp(result, "ok")) {
        fprintf(stderr, "[web-auth] %s; refusing to start\n", result);
        _exit(78);
    }
}
