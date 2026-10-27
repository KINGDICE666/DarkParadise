# Browser guest gateway

This is an experimental native guest adapter for **Linux x86 BYOND 516.1682**,
ELF build ID `e9cdd7c77f6ceac5c3ac42b6f5574f388a969bde`. It modifies two engine
instruction sites in memory. It is not a documented BYOND setting or an official
authentication provider. Engine files on disk are unchanged. An unsupported build
is rejected before installing hooks; do not reuse offsets for another build.

The gateway issues a random 128-bit, single-use ticket, valid for 60 seconds.
The DD adapter consumes it through a mode-0600 Unix socket and completes the
connection as a guest. Registered BYOND identities cannot be selected by this
interface. Other key formats and DreamSeeker authentication use the original
engine code. Guest IDs are salted per ticket so clients behind the gateway do
not share the engine's default IP-derived guest key and CID.

## Build and start

Build in an environment with 32-bit glibc development files:

```sh
gcc -m32 -shared -fPIC -O2 -Wall -Wextra -Werror \
  -o libdpwebauth.so native-auth.c -ldl
node --test tickets.test.mjs
```

After changing `tgui/packages/tgui-setup/helpers.js`, run `bun run build:helpers`
from that package directory and include `tgui/public/helpers.min.js` before
compiling the world. The main Rspack build does not rebuild this injected file.

For Paradise, put `libdpwebauth.so` in the game working directory. Compile the
DM changes in this branch and enable `WEB_GUEST_LOGIN` in `config/config.txt`.
Disable `GUEST_BAN`; `LAUNCHER_REQUIRED` can remain enabled for DreamSeeker guests.
Start DD with `-webclient`. The world loads the adapter with `call_ext()` and
disables the web guest flag if initialization fails. Windows startup is unchanged
when the flag is disabled.

The DD process needs `BYOND_SYSTEM` pointing to its BYOND installation root,
including when it is started by TGServer inside Docker. It is also used for skin
generation; serving JavaScript alone cannot replace it. Set `BYOND_WEB_DIR` on
the gateway to that same installation's host-side `web` directory if needed.

Start the gateway in this directory, using the same socket file as DD:

```sh
KEY_MODE=self \
AUTH_SOCKET=/srv/paradise/data/web-auth.sock \
DD_HOST=127.0.0.1 DD_PORT=7777 \
GATEWAY_HOST=127.0.0.1 GATEWAY_PORT=8090 \
node gateway.mjs
```

Set `ASSET_ROOTS` to a JSON array containing only the public resource directories
of the deployed game, for example `ASSET_ROOTS='["/srv/paradise/tgui/public"]'`.
Paradise loads TGUI bundles through `asset.<md5>.js` and `.css` URLs that DD does
not serve by name. The gateway indexes the actual file bytes and serves those
hashes with their correct MIME types. Files must match the running compiled
world; bundles from a different checkout can have different hashes. Symlinks,
private file extensions, and files larger than 32 MiB are excluded. Never set
this to a general repository, configuration, or home directory.

For a minimal standalone test world, alternatively load the adapter at startup:

```sh
DP_WEB_AUTH_SOCKET=/srv/paradise/data/web-auth.sock \
LD_PRELOAD=/srv/paradise/libdpwebauth.so \
DreamDaemon test.dmb 7790 -trusted -webclient
```

With Docker, bind-mount the socket's **directory** into DD, not an individual
socket inode. Use the host path in `AUTH_SOCKET` and the container path in DD.
The native adapter currently requires DD and the gateway to share a trusted host.
The socket and ticket endpoint are different interfaces: never publish the socket
through HTTP or grant it access from untrusted processes.

`BASE_PATH=/game` supports an nginx location that strips that prefix. Set
`PUBLIC_URL=https://example.org/game` to control `/query`'s advertised URL.
HTTP and WebSocket requests sent directly with that prefix also work.

## Checks and limits

```sh
python3 smoke_test.py http://127.0.0.1:8090 --connections 20
```

This checks actual DD guest admission, distinct guest identities, replay
rejection, and rejection of unissued tickets. It does not prove map rendering or
TGUI compatibility: verify those in a browser as well. A successful page must
reach the game's lobby, not just an open WebSocket or a completed download.

The TGUI bridge forwards Topic, winset, and winget through the native browser
client. Protocol strings are decoded and encoded as UTF-8 for BYOND 516.
Topic queries retain their leading `?`; control types returned to DM use the
DreamSeeker uppercase spelling. `winget(null, "dpi")` reports `1`: popup sizes
and page content are both CSS pixels, so DM must not zoom browse windows out.
Showing or hiding a control also shows or hides the popup that holds it, and
`titlebar=0` from `browse()` reaches existing and new windows. DD parses web
client commands as text, so an unquoted text argument swallows the rest of the
line; the key name in `keyDown`/`keyUp` macros is quoted before sending. The
verb name must match exactly: DD 516.1682 corrupts memory while resolving a
web client command whose verb name differs only in case (`KeyDown` for
`keyDown`), and after a few hundred such commands it either drops the client
with `Unexpected message 246` or crashes in `strdup`. The bridge rewrites key
macros to the exact names. Loaded browser frames keep their browsing
context when controls move or their popup is hidden. Initial repeated stat tab
notifications are coalesced, and all Topic messages are held to 8 per second so
the startup burst stays under the world's per-second Topic limit.

The stock web client predates BYOND 515: `TOP`, `BOTTOM`, `LEFT` and `RIGHT` in
`screen_loc` are translated to compass keywords. DD 516 flattens maptext styles
for the web client and drops classes and `-dm-text-outline`, so the map style's
`.maptext` rule is applied as the base of every maptext except legacy `<font
face>` text; fully transparent colors fall back to it, percent sizes are taken
from 10pt as DD writes them, outlines are stroked, and lines are spaced by the
font height. Maptext overlays are placed from the bottom-left of their icon with
`maptext_x/y`. Font resources are still preloaded so maptext fonts register. Stat panel
theme, font and tab style commands are applied directly while `statbrowser.js`
functions are not global in the strict inline script.

For local frontend development, `dev-proxy.mjs` binds to `127.0.0.1:8179` and
forwards requests to `DEV_UPSTREAM_HOST` / `DEV_UPSTREAM_PORT`. Supply the exact
stock JavaScript through `DEV_VENDOR_FILE`, a snapshot of deployed public
bundles through `DEV_ASSET_DIR`, and optionally the old/new helper files through
`DEV_LEGACY_HELPERS` / `DEV_TGUI_HELPERS`. This changes no remote files or services,
but a browser connection still joins the upstream game as a test guest. The
proxy logs bounded packet metadata and local frame errors, never ticket values.

Run `node --test tools/webclient/*.test.mjs` from the repository root. Setting
`BYOND_WEBCLIENT_JS` to the stock vendor file enables compatibility tests against
the real patched functions. Unix socket tests are skipped on Windows.

The page displays download progress and reports failed authentication,
disconnection, and a stalled download with a retry button. The vendor cache queue
is patched to continue after a failed resource, which otherwise strands queued
downloads. Failed URLs are printed in the browser console.
The obsolete client-wide resource preload is disabled; resources load when used,
which also avoids sending WOFF2 fonts through its incompatible OpenType parser.
Generated HTML base URLs are routed through the gateway for HTTPS and subpaths.

The socket stores the gateway's observed player IP. Only a direct loopback
reverse proxy may supply `X-Forwarded-For`; its final appended address is used.
Engine peer-address rewriting is not enabled: DD also uses that address to
authorize HTTP resource downloads. Production IP-ban handling behind this proxy
needs further integration. Web connections never receive localhost auto-admin
rights through Paradise's localhost helper.

To revert, disable `WEB_GUEST_LOGIN`, remove `-webclient` if desired, and restart
DD normally. `KEY_MODE=byond` restores the BYOND embed page and does not run a
ticket authority. No BYOND hub protocol implementation or hub impersonation is
included.
