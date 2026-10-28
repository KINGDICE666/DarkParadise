#include "native-auth.c"
#include <assert.h>

static unsigned char connection_data[1024];
static int closed;
static int guard_ok = 1;
static int connected = 1;

static void *mock_find(unsigned short id) {
    return id == 0 && connected ? connection_data : NULL;
}

static unsigned char mock_guard(void *connection, int update) {
    (void)connection;
    (void)update;
    return guard_ok;
}

static void mock_close(unsigned short id, int reason, int extra) {
    (void)id;
    (void)reason;
    (void)extra;
    ++closed;
}

int main(void) {
    struct engine_build test_build = {.token_offset = 0x80};
    build = &test_build;
    find_connection = mock_find;
    connection_guard = mock_guard;
    close_connection = mock_close;
    connection_data[0x26] = 4;
    *(const char **)(connection_data + test_build.token_offset) = "dpweb-v1:0123456789abcdef0123456789abcdef";

    unsigned char code[] = {0x6a, 0, 0x6a, 1, 0x6a, 0, 0xb8, 0, 0, 0, 0, 0xff, 0xd0, 0x83, 0xc4, 12, 0xc3};
    unsigned char *hub = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    assert(hub != MAP_FAILED);
    memcpy(hub, code, sizeof(code));
    uint32_t callback = (uintptr_t)hub_close_connection;
    memcpy(hub + 7, &callback, sizeof(callback));
    assert(mprotect(hub, 4096, PROT_READ | PROT_EXEC) == 0);
    test_build.hub_reply_return = (uintptr_t)(hub + 13);
    void (*reply)(void) = (void *)hub;

    reply();
    assert(closed == 0);
    hub_close_connection(0, 1, 0);
    assert(closed == 1);
    guard_ok = 0;
    reply();
    assert(closed == 2);
    guard_ok = 1;
    connection_data[0x26] = 0;
    reply();
    assert(closed == 3);
    connection_data[0x26] = 4;
    *(const char **)(connection_data + test_build.token_offset) = "ordinary BYOND token";
    reply();
    assert(closed == 4);
    *(const char **)(connection_data + test_build.token_offset) = NULL;
    reply();
    assert(closed == 5);
    connected = 0;
    reply();
    assert(closed == 6);
    connected = 1;
    *(const char **)(connection_data + test_build.token_offset) = "dpweb-v1:0123456789abcdef0123456789abcdef";
    assert(mprotect(hub, 4096, PROT_READ | PROT_WRITE) == 0);
    hub[3] = 9;
    assert(mprotect(hub, 4096, PROT_READ | PROT_EXEC) == 0);
    reply();
    assert(closed == 7);
    munmap(hub, 4096);
    puts("PASS: late hub guard preserves ordinary disconnects and admission checks");
}
