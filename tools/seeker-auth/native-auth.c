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
#include <sys/stat.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

static const unsigned char expected_build[] = {
    0xe9, 0xcd, 0xd7, 0xc7, 0x7f, 0x6c, 0xea, 0xc5, 0xc3, 0xac,
    0x42, 0xb6, 0xf5, 0x57, 0x4f, 0x38, 0x8a, 0x96, 0x9b, 0xde
};
static uintptr_t engine_base;
static int build_matches;
static const char *auth_socket;
static void (*original_key_message)(void *, unsigned short, int);
static void *(*find_connection)(unsigned short);
static void (*close_connection)(unsigned short, int, int);
static unsigned char (*connection_guard)(void *, int);
static uint32_t (*intern_string)(const char *, int);
static void (*assign_string)(uint32_t *, uint32_t);
static uint32_t (*canonical_string)(uint32_t);
static const void *(*sha256_digest)(void);
static unsigned char *(*make_hmac)(const void *, const void *, int, const unsigned char *, size_t, unsigned char *, unsigned int *);
static int (*secure_compare)(const void *, const void *, size_t);
static unsigned char signing_key[32];
static struct {
    char guest[32], account[33], address[46], cid[16], proof[33];
    time_t expires;
} pending[1024];
static char identity_result[128];

const char *identity(int argc, const char **argv) {
    if (argc != 4 || !argv || strlen(argv[3]) != 32) return "";
    time_t now = time(NULL);
    for (unsigned i = 0; i < 1024; ++i) {
        if (pending[i].expires <= now || strcmp(argv[0], pending[i].guest) || strcmp(argv[1], pending[i].address) || strcmp(argv[2], pending[i].cid) || secure_compare(argv[3], pending[i].proof, 32)) continue;
        snprintf(identity_result, sizeof(identity_result), "guest=%.31s&ckey=%.32s", pending[i].guest, pending[i].account);
        pending[i].expires = 0;
        return identity_result;
    }
    return "";
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

static int consume_ticket(const char *token, char guest[32], char account[33], char address[46]) {
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
    char request[144];
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
    if (!space || space == reply + 9 || space - (reply + 3) >= 32) goto done;
    for (char *digit = reply + 9; digit < space; ++digit) if (*digit < '0' || *digit > '9') goto done;
    char *account_start = space + 1;
    char *account_end = strchr(account_start, ' ');
    if (!account_end || account_end == account_start || account_end - account_start > 32 || strlen(account_end + 1) >= 46) goto done;
    if (!(account_end - account_start == 1 && *account_start == '-')) {
        for (char *letter = account_start; letter < account_end; ++letter) {
            if (!((*letter >= 'a' && *letter <= 'z') || (*letter >= '0' && *letter <= '9'))) goto done;
        }
        if (!strncmp(account_start, "guest", 5) || !strncmp(account_start, "stm", 3)) goto done;
    }
    unsigned char packed_address[16];
    if (inet_pton(AF_INET, account_end + 1, packed_address) != 1 && inet_pton(AF_INET6, account_end + 1, packed_address) != 1) goto done;
    memcpy(guest, reply + 3, space - (reply + 3));
    guest[space - (reply + 3)] = 0;
    memcpy(account, account_start, account_end - account_start);
    account[account_end - account_start] = 0;
    strcpy(address, account_end + 1);
    ok = 1;
done:
    close(fd);
    return ok;
}

static void key_message(void *message, unsigned short id, int mode) {
    unsigned char *connection = find_connection(id);
    uint32_t length = *(uint32_t *)((char *)message + 4);
    const char *token = *(const char **)((char *)message + 12);
    if (*(unsigned short *)message != 26 || !token || length < 8 || memcmp(token, "seeker-v", 8)) {
        original_key_message(message, id, mode);
        return;
    }
    if (!connection || (connection[0x26] & 4) || *(unsigned short *)(connection + 0x34) != 1) {
        close_connection(id, 9, 0);
        return;
    }
    char guest[32];
    char account[33];
    char address[46];
    int valid = length == 140 && !memcmp(token, "seeker-v2:", 10) && token[74] == ':' && token[139] == 0;
    for (unsigned i = 10; valid && i < 74; ++i) {
        valid = (token[i] >= '0' && token[i] <= '9') || (token[i] >= 'a' && token[i] <= 'f');
    }
    unsigned char supplied_mac[32], expected_mac[32];
    for (unsigned i = 0; valid && i < 32; ++i) {
        unsigned char high = token[75 + i * 2], low = token[76 + i * 2];
        if (!((high >= '0' && high <= '9') || (high >= 'a' && high <= 'f')) ||
            !((low >= '0' && low <= '9') || (low >= 'a' && low <= 'f'))) {
            valid = 0;
            break;
        }
        supplied_mac[i] = ((high <= '9' ? high - '0' : high - 'a' + 10) << 4) | (low <= '9' ? low - '0' : low - 'a' + 10);
    }
    unsigned int mac_length = 0;
    if (valid) valid = make_hmac(sha256_digest(), signing_key, sizeof(signing_key), (const unsigned char *)token, 74, expected_mac, &mac_length) && mac_length == 32 && !secure_compare(supplied_mac, expected_mac, 32);
    if (!valid || !consume_ticket(token, guest, account, address)) {
        fprintf(stderr, "[seeker-auth] guest ticket rejected\n");
        close_connection(id, 9, 0);
        return;
    }
    unsigned slot;
    for (slot = 0; slot < 1024; ++slot) if (pending[slot].expires <= time(NULL)) break;
    if (slot == 1024) {
        close_connection(id, 9, 0);
        return;
    }
    if (!connection_guard(connection, 0)) {
        fprintf(stderr, "[seeker-auth] connection state integrity check failed\n");
        close_connection(id, 8, 0);
        return;
    }
    char seed_address[46];
    unsigned long long guest_number = strtoull(guest + 6, NULL, 10);
    snprintf(seed_address, sizeof(seed_address), "2001:db8::%x:%x:%x", (unsigned)(guest_number >> 32), (unsigned)(guest_number >> 16) & 65535, (unsigned)guest_number & 65535);
    assign_string((uint32_t *)(connection + 4), intern_string(seed_address, -1));
    connection_guard(connection, 1);
    static const unsigned char guest_data[] = {
        0x00,0x00,0x7e,0xcc,0x5a,0x2e,0x89,0x35,0x73,0xd7,0x6d,0x97,0x6c,0xb5,0xf6,0x00,
        0x11,0x74,0x09,0x6f,0x7f,0x45,0x56,0xae,0xbd,0x6c,0x20,0x1f,0x2c,0x2d,0xe9,0x42,
        0x84,0xa7,0x66,0x0d,0xf1,0x7f,0x20,0x81,0xcc,0x1a,0x00,0x00,0x00,0x00,0x00
    };
    char login_topic[41];
    snprintf(login_topic, sizeof(login_topic), "?seeker=%.32s", token + 10);
    unsigned char guest_login[sizeof(guest_data) + 40];
    memcpy(guest_login, login_topic, 40);
    memcpy(guest_login + 40, guest_data, sizeof(guest_data));
    uint32_t saved_length = *(uint32_t *)((char *)message + 4);
    uint32_t saved_capacity = *(uint32_t *)((char *)message + 8);
    void *saved_data = *(void **)((char *)message + 12);
    *(uint32_t *)((char *)message + 4) = sizeof(guest_login);
    *(uint32_t *)((char *)message + 8) = sizeof(guest_login);
    *(void **)((char *)message + 12) = guest_login;
    original_key_message(message, id, mode);
    *(uint32_t *)((char *)message + 4) = saved_length;
    *(uint32_t *)((char *)message + 8) = saved_capacity;
    *(void **)((char *)message + 12) = saved_data;
    connection = find_connection(id);
    if (!connection) return;
    if (!connection_guard(connection, 0)) {
        close_connection(id, 8, 0);
        return;
    }
    char *guest_key = strdup(guest);
    if (!guest_key) _exit(78);
    free(*(char **)(connection + 0x38));
    *(char **)(connection + 0x38) = guest_key;
    uint32_t key_id = intern_string(guest, -1);
    assign_string((uint32_t *)(connection + 0x54), key_id);
    assign_string((uint32_t *)(connection + 0x4c), key_id);
    assign_string((uint32_t *)(connection + 0x50), canonical_string(key_id));
    assign_string((uint32_t *)(connection + 4), intern_string(address, -1));
    uint32_t cid = (uint32_t)strtoull(guest + 6, NULL, 10);
    *(uint32_t *)(connection + 0x0c) = cid == 0 || cid == 2147483647 ? 1 : cid;
    char cid_text[16];
    snprintf(cid_text, sizeof(cid_text), "%u", *(uint32_t *)(connection + 0x0c));
    assign_string((uint32_t *)(connection + 8), intern_string(cid_text, -1));
    strcpy(pending[slot].guest, guest);
    strcpy(pending[slot].account, !strcmp(account, "-") ? "" : account);
    strcpy(pending[slot].address, address);
    strcpy(pending[slot].cid, cid_text);
    memcpy(pending[slot].proof, token + 10, 32);
    pending[slot].proof[32] = 0;
    pending[slot].expires = time(NULL) + 30;
    connection_guard(connection, 1);
}

static const char *install_adapter(const char *socket_path) {
    if (original_key_message) return !strcmp(auth_socket, socket_path) ? "ok" : "adapter is already configured";
    if (!socket_path || !*socket_path || strlen(socket_path) >= sizeof(((struct sockaddr_un *)0)->sun_path)) return "invalid auth socket path";
    dl_iterate_phdr(find_engine, NULL);
    const unsigned char preamble[] = {0x55, 0x89, 0xe5, 0x57, 0x56};
    unsigned char *target = (void *)(engine_base + 0x35f3e0);
    if (sizeof(void *) != 4 || !engine_base || !build_matches || memcmp(target, preamble, 5)) {
        return "unsupported BYOND binary (requires Linux x86 516.1682, build e9cdd7c77f6ceac5c3ac42b6f5574f388a969bde)";
    }
    char key_path[128];
    const char *separator = strrchr(socket_path, '/');
    if (separator) snprintf(key_path, sizeof(key_path), "%.*s/ticket.key", (int)(separator - socket_path), socket_path);
    else strcpy(key_path, "ticket.key");
    int key_fd = open(key_path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (key_fd < 0) return "cannot read Seeker ticket signing key";
    struct stat key_info;
    int key_valid = !fstat(key_fd, &key_info) && S_ISREG(key_info.st_mode) && key_info.st_size == (off_t)sizeof(signing_key) && !(key_info.st_mode & 077);
    if (key_valid) key_valid = read(key_fd, signing_key, sizeof(signing_key)) == (ssize_t)sizeof(signing_key);
    close(key_fd);
    if (!key_valid) return "Seeker ticket signing key must be 32 bytes with mode 0600";
    void *crypto_library = dlopen("libcrypto.so.3", RTLD_NOW | RTLD_LOCAL);
    if (!crypto_library) return "Seeker authentication requires 32-bit OpenSSL 3";
    sha256_digest = dlsym(crypto_library, "EVP_sha256");
    make_hmac = dlsym(crypto_library, "HMAC");
    secure_compare = dlsym(crypto_library, "CRYPTO_memcmp");
    if (!sha256_digest || !make_hmac || !secure_compare) {
        dlclose(crypto_library);
        return "Seeker authentication requires OpenSSL HMAC-SHA256";
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
    close_connection = (void *)(engine_base + 0x3412d0);
    connection_guard = (void *)(engine_base + 0x407e10);
    intern_string = (void *)(engine_base + 0x2e29b0);
    assign_string = (void *)(engine_base + 0x2e4080);
    canonical_string = (void *)(engine_base + 0x2edb10);
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
    if (mprotect(page, page_size, PROT_READ | PROT_EXEC)) _exit(78);
    fprintf(stderr, "[seeker-auth] native ticket adapter enabled for BYOND 516.1682\n");
    return "ok";
}

const char *initialize(int argc, const char **argv) {
    if (argc != 1 || !argv) return "expected one auth socket path";
    return install_adapter(argv[0]);
}

