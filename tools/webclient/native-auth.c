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

/* Linux x86 adapter, pinned to the upstream ELF builds below. */
struct engine_build {
    const char *version;
    unsigned char id[20];
    uintptr_t key_message;
    uintptr_t seed_call;
    unsigned char seed_bytes[5];
    uintptr_t find_connection;
    uintptr_t complete_login;
    uintptr_t close_connection;
    uintptr_t connection_guard;
    uintptr_t copy_string;
    uintptr_t lookup_string;
    unsigned token_offset;
    uintptr_t map_flag_reserve;
    uintptr_t map_flag_remove;
    uintptr_t write_byte;
    uintptr_t write_word;
    uintptr_t hub_reply_return;
};
static const struct engine_build builds[] = {
    {
        "516.1682",
        {0xe9, 0xcd, 0xd7, 0xc7, 0x7f, 0x6c, 0xea, 0xc5, 0xc3, 0xac,
         0x42, 0xb6, 0xf5, 0x57, 0x4f, 0x38, 0x8a, 0x96, 0x9b, 0xde},
        0x3f2b80, 0x3f2101, {0xe8, 0x9a, 0x09, 0xef, 0xff},
        0x405c60, 0x3f1e90, 0x3412d0, 0x407e10, 0x4aa440, 0x2e2aa0, 0x2f8,
        0x45f5f9, 0x45f6d6, 0x480450, 0x480530,
        0x46eea9,
    },
    {
        "516.1688",
        {0xa3, 0x0a, 0x79, 0x44, 0x1d, 0x3f, 0x71, 0x76, 0xe8, 0xfe,
         0x23, 0xb5, 0xf2, 0x89, 0x7f, 0xc6, 0x19, 0x72, 0xb4, 0xaa},
        0x3f3580, 0x3f2b01, {0xe8, 0xba, 0x00, 0xef, 0xff},
        0x406690, 0x3f2890, 0x341a20, 0x408840, 0x4ab1a0, 0x2e2bc0, 0x300,
        0x460069, 0x460146, 0x480ed0, 0x480fb0,
        0,
    },
};
static uintptr_t engine_base;
static const struct engine_build *build;
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

static void hub_close_connection(unsigned short id, int reason, int extra) {
    uintptr_t caller = (uintptr_t)__builtin_return_address(0);
    if (reason == 1) {
        unsigned char *connection = find_connection(id);
        const char *token = connection && (connection[0x26] & 4) && connection_guard(connection, 0)
            ? *(const char **)(connection + build->token_offset) : NULL;
        int local_guest = token && !strncmp(token, "dpweb-v1:", 9);
        if (local_guest && caller == engine_base + build->hub_reply_return) {
            fprintf(stderr, "[web-auth] ignored late hub reply for admitted local guest\n");
            return;
        }
        fprintf(stderr, "[web-auth] connection closed with reason 1 from +0x%lx%s\n",
            (unsigned long)(caller - engine_base), local_guest ? " (local guest)" : "");
        fflush(stderr);
    }
    close_connection(id, reason, extra);
}

static void *make_trampoline(const unsigned char *target) {
    unsigned char *trampoline = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (trampoline == MAP_FAILED) return NULL;
    memcpy(trampoline, target, 5);
    trampoline[5] = 0xe9;
    int32_t relative = (intptr_t)(target + 5) - (intptr_t)(trampoline + 10);
    memcpy(trampoline + 6, &relative, sizeof(relative));
    if (mprotect(trampoline, 4096, PROT_READ | PROT_EXEC)) {
        munmap(trampoline, 4096);
        return NULL;
    }
    return trampoline;
}

static void install_hub_close_guard(long page_size, unsigned char *target) {
    if (!build->hub_reply_return) return;
    close_connection = make_trampoline(target);
    if (!close_connection) _exit(78);
    void *page = (void *)((uintptr_t)target & ~((uintptr_t)page_size - 1));
    if (mprotect(page, page_size, PROT_READ | PROT_WRITE | PROT_EXEC)) _exit(78);
    int32_t relative = (intptr_t)hub_close_connection - (intptr_t)(target + 5);
    target[0] = 0xe9;
    memcpy(target + 1, &relative, sizeof(relative));
    if (mprotect(page, page_size, PROT_READ | PROT_EXEC)) _exit(78);
}

/* The world serializer backpatches a uint16 flag field, but upstream reserves
 * only one byte. That overwrites the low byte of every updated atom reference.
 * Reserve two bytes for updates AND removals; the browser reads uint16 flags
 * and the existing bit-256 vis_contents payload. HUD uses a separate serializer.
 * These call sites are checked in addition to the exact ELF build ID. */
static int map_call_matches(uintptr_t offset) {
    const unsigned char *call = (void *)(engine_base + offset);
    int32_t relative;
    memcpy(&relative, call + 1, sizeof(relative));
    return call[0] == 0xe8 && offset + 5 + relative == build->write_byte;
}

static void install_map_flags(long page_size) {
    uintptr_t first = engine_base + build->map_flag_reserve;
    uintptr_t last = engine_base + build->map_flag_remove + 5;
    void *page = (void *)(first & ~((uintptr_t)page_size - 1));
    size_t span = last - (uintptr_t)page;
    if (mprotect(page, span, PROT_READ | PROT_WRITE | PROT_EXEC)) _exit(78);
    const uintptr_t sites[] = {build->map_flag_reserve, build->map_flag_remove};
    for (unsigned i = 0; i < sizeof(sites) / sizeof(sites[0]); ++i) {
        int32_t relative = (int32_t)(build->write_word - (sites[i] + 5));
        memcpy((void *)(engine_base + sites[i] + 1), &relative, sizeof(relative));
    }
    if (mprotect(page, span, PROT_READ | PROT_EXEC)) _exit(78);
    fprintf(stderr, "[web-auth] complete map protocol enabled (uint16 flags, full references, vis_contents)\n");
}

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
                note->n_descsz == sizeof(builds[0].id) &&
                !memcmp(cursor + sizeof(*note), "GNU", 4)) {
                for (unsigned b = 0; b < sizeof(builds) / sizeof(builds[0]); ++b) {
                    if (!memcmp(cursor + sizeof(*note) + names, builds[b].id, sizeof(builds[b].id))) build = &builds[b];
                }
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
    *(char **)(connection + build->token_offset) = copy_string(token);
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
    if (sizeof(void *) != 4 || !engine_base || !build) {
        return "unsupported BYOND binary (requires Linux x86 516.1682 or 516.1688)";
    }
    unsigned char *target = (void *)(engine_base + build->key_message);
    unsigned char *seed_target = (void *)(engine_base + build->seed_call);
    unsigned char *close_target = (void *)(engine_base + build->close_connection);
    const unsigned char hub_call[] = {0x8b, 0x45, 0xd0, 0xff, 0xd0, 0x83, 0xc4, 0x10};
    if (memcmp(target, preamble, 5) || memcmp(seed_target, build->seed_bytes, 5) ||
        (build->hub_reply_return && (memcmp(close_target, preamble, 5) ||
            memcmp((void *)(engine_base + build->hub_reply_return - 5), hub_call, sizeof(hub_call)))) ||
        !map_call_matches(build->map_flag_reserve) || !map_call_matches(build->map_flag_remove)) {
        return "unexpected BYOND code at the adapter hook sites";
    }
    unsigned char *trampoline = make_trampoline(target);
    if (!trampoline) return "cannot allocate adapter trampoline";
    find_connection = (void *)(engine_base + build->find_connection);
    complete_login = (void *)(engine_base + build->complete_login);
    close_connection = (void *)(engine_base + build->close_connection);
    connection_guard = (void *)(engine_base + build->connection_guard);
    copy_string = (void *)(engine_base + build->copy_string);
    lookup_string = (void *)(engine_base + build->lookup_string);
    long page_size = sysconf(_SC_PAGESIZE);
    uintptr_t first = (uintptr_t)(target < seed_target ? target : seed_target);
    uintptr_t last = (uintptr_t)(target < seed_target ? seed_target : target) + 5;
    void *page = (void *)(first & ~((uintptr_t)page_size - 1));
    size_t span = last - (uintptr_t)page;
    if (mprotect(page, span, PROT_READ | PROT_WRITE | PROT_EXEC)) {
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
    if (mprotect(page, span, PROT_READ | PROT_EXEC)) _exit(78);
    install_map_flags(page_size);
    install_hub_close_guard(page_size, close_target);
    fprintf(stderr, "[web-auth] local guest adapter enabled for BYOND %s\n", build->version);
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
