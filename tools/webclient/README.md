# Browser guest gateway

This is an experimental native guest and map adapter for **Linux x86 BYOND
516.1682** (ELF build ID `e9cdd7c77f6ceac5c3ac42b6f5574f388a969bde`) and
**516.1688** (`a30a79441d3f7176e8fe23b5f2897fc61972b4aa`). It modifies four engine
instruction sites in memory, plus a narrowly scoped late Hub reply guard on
516.1682. It is not a documented BYOND setting or an official
authentication provider. Engine files on disk are unchanged. An unsupported build
is rejected before installing hooks; do not reuse offsets for another build.

Deploy the adapter and gateway JavaScript together, then restart the test DD and
reload its browser clients. The adapter repairs the world movable serializer:
upstream reserves one flag byte but backpatches two, overwriting the low byte of
the following atom reference. Different objects consequently share IDs and
overwrite each other. Both updates and removals now reserve two bytes. The client
reads the uint16 world flags and the bit-256 `vis_contents` list; HUD flags remain
one byte. A cached atom is also added back to the active list when it reenters
the view. The TCP/WebSocket gateway still forwards bytes unchanged. This repair
does not require a DreamSeeker-to-WebSocket transcoder.

The gateway issues a random 128-bit, single-use ticket, valid for 60 seconds.
The DD adapter consumes it through a mode-0600 Unix socket and completes the
connection as a guest. Registered BYOND identities cannot be selected by this
interface. Other key formats and DreamSeeker authentication use the original
engine code. Guest IDs are salted per ticket so clients behind the gateway do
not share the engine's default IP-derived guest key and CID.

On 516.1682 a late Hub reply can otherwise disconnect an admitted local guest
with quit code 1 after several minutes. The close guard applies only to the
verified Hub return address, that quit reason, and an intact web connection
whose stored token came from the local ticket admission path. Other tokens,
callers and disconnect reasons retain the original behavior. The guard's engine
instructions are checked before installation, like the other hooks.

## Build and start

Build in an environment with 32-bit glibc development files:

```sh
gcc -m32 -shared -fPIC -O2 -Wall -Wextra -Werror \
  -o libdpwebauth.so native-auth.c -ldl
gcc -m32 -O2 -Wall -Wextra -Werror -o native-auth-test native-auth.test.c -ldl
./native-auth-test
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
line. Key macros never reach that parser: DD 516.1682 corrupts memory while
resolving web client commands and either drops the client with `Unexpected
message 246` or crashes in `strdup`. A mismatched verb case (`KeyDown` for
`keyDown`) makes it happen within a few hundred commands, and bursts of
correctly spelled key commands still crashed production. The bridge sends
`keyDown`/`keyUp` as immediate `?dp_key=` Topics instead, outside the Topic rate
queue, and `/client/Topic` hands them to the key verbs before rate limiting and
href logging. Deploy the game code before a bridge that sends them. Other
commands get the exact spelling of a verb the client knows: the first word of
each line is matched against the verb list DD sent, so `ooc "..."` from the skin
input reaches DD as `OOC "..."`. Hidden verbs are not in that list and must be
spelled exactly in the skin and in DM. Loaded browser frames keep their browsing
context when controls move or their popup is hidden. Initial repeated stat tab
notifications are coalesced, and all Topic messages are held to 6 per second so
the startup burst stays under the world's per-second Topic limit.

The stock web client predates BYOND 515: `TOP`, `BOTTOM`, `LEFT` and `RIGHT` in
`screen_loc` are translated to compass keywords. DD 516 flattens maptext styles
for the web client and drops classes and `-dm-text-outline`, so the map style's
`.maptext` rule is applied as the base of every maptext except legacy `<font
face>` text; fully transparent colors fall back to that rule. A span with only
a class arrives without its styles, so maptext alignment must be an inline
`text-align` (runechat keeps `center` inline for this reason). Percent sizes are taken
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
Set `DEV_COMPLETE_MAP=1` only when its upstream DD has the repaired native
adapter. The development proxy defaults to the old byte-flag format so it can
inspect an existing server before that server is upgraded.

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

The repaired stream preserves `vis_contents`, but the stock browser compositor
still lacks native vis inheritance and render targets. Keep the existing lighting
bridge: `SSweb_lighting` mirrors each lighting object
near a web client's eye into `client.images` and adds the mob's lighting cutoff
as a full-screen additive overlay. The bridge folds the overlay lighting and
emissive planes into the lighting plane with additive blending, multiplies that
plane over the world, and draws each turf lighting matrix from the raw corner
weights of `lighting_object.dmi`: the browser premultiplies the alpha weight
channel when decoding the icon. The lighting view resets its sent-image cache on
`COMSIG_CLIENT_MOB_LOGIN`, because mob login clears `client.images` even if the
eye stays on the same turf. This restores lighting after ghosting or changing
bodies. The full-screen lighting backdrops, render
plates are not drawn. Empty plane masters are hidden instead of
being flattened into zero-size framebuffers. The activity ping runs every 30
seconds and is also driven from a worker, because DD drops web clients whose
background tab has throttled timers.

World rendering respects `invisibility` even with `SEE_TURFS`, `SEE_OBJS` or
`SEE_MOBS`; those sight flags do not reveal abstract editor landmarks.
The `SEE_TURFS` transition also clears cached darkness masks from the living
view so becoming a ghost does not leave the floor black. Grouped
overlays and underlays share their parent's bottom edge, including 64px speech
bubbles and maptext on smaller displays. Maptext keeps HTML line breaks and
distinguishes pixel font sizes from point sizes.

The space and parallax planes are retained. HUD packets omit the parallax
holder's visual children, so the bridge projects the server's active off-map
parallax layers onto that holder. Layer candidates are indexed on world packets;
stationary layers reuse their geometry. Additive tiled layers do not need a
large flattened framebuffer. This covers the game's parallax holder rather than
implementing arbitrary native `vis_flags` inheritance or render targets.

Hidden atoms stop ticking once their persistent glide finishes. Simple DMI
animations keep their timers but rebuild their icons only when the frame changes;
flicks, moving atoms, client images and layered appearances retain the original
update behavior. Rendering validation for these changes uses BYOND **516.1682**.
