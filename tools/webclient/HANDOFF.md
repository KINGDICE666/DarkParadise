# SS13 browser crossplay — paused at user's request, 2026-10-26

User explicitly said: «Останавливайся и записывай в память, все на сегодня». Stop work until user resumes. Do not create reminders or automatically continue.

## Goal and actual result

Goal: browser entry at http://92.63.189.21:7779/ into the SAME Dream Daemon / round as ordinary DreamSeeker, like ALEPH. User clarified this is crossplay, not a separate browser game.

NOT FINISHED. Own guest ticket authentication works on the production DD; full browser gameplay still fails. Browser receives the Paradise lobby artwork and welcome messages, but TGUI/stat/chat remain loading or fallback, and DD eventually disconnects with Quit code 8. Do not describe the task as done.

Last useful evidence: native JS logs `Browser Topic queued` eight times around 02:21:13–16 UTC after a direct Topic experiment, but TGUI still does not become ready. The next observation showed disconnected. This narrows the issue to actual command dispatch / native connection readiness / heartbeat, not obtaining the guest key. Check native packet admission/state and message 183 acknowledgments as hypotheses; neither is established.

## Environment and access

- Local workspace C:\Users\Z\Desktop\Paradise, PowerShell. Local HEAD c756617d5b376a7fe768043738692a2e557e20b8. Own changes uncommitted; no local branch or PR created.
- SSH root@92.63.189.21, port 52200, existing SSH key. Port 22 times out.
- Read paradise-dm skill for any DM changes; it was already used. No subagents allowed unless user explicitly requests.
- Never print credentials or complete process arguments. `docker top tgs` previously exposed a tgs_key. Read only whitelisted environment variables and process columns. Game logs can include secret topic keys, so filter rather than dumping their tails.
- API credentials root-only /etc/darkparadise/tgs-deploy.json. Use programmatically, never output values.

## Current live server state — leave it running

- Main TGServer container `tgs`, tgstation/server:v6.19.2, host network; API http://127.0.0.1:5000/api.
- Main DD running under TGS on port 7777, allowWebClient=true, compile job 172, round 698 at last check. Status was 2 (online). Main map initialization took ~260 seconds, completed at 02:16:07 UTC.
- Public gateway `darkparadise-webclient.service`, active and enabled, port 7779 -> 127.0.0.1:7777. Persistent unit /etc/systemd/system/darkparadise-webclient.service, source /root/webclient-test/gateway.
- Gateway KEY_MODE=self; AUTH_SOCKET=/home/tgs/tgs_instances/darkparadise/Configuration/GameStaticFiles/data/web-auth.sock; BASE_PATH=/webtest; PUBLIC_URL=https://serverhostdarkparadise.ru/webtest; BYOND_WEB_DIR=/home/tgs/tgs_instances/darkparadise/Byond/516.1682/byond/web.
- Both direct IP root and HTTPS /webtest paths proxy to the same DD. HTTPS /webtest/query tested successfully. Browser gameplay itself unverified over HTTPS.
- TGS container lacked BYOND_SYSTEM. Recreated it preserving full inspected Config/HostConfig and all persistent/anonymous volumes, with BYOND_SYSTEM=/tgs_instances/darkparadise/Byond/516.1682/byond. This fixed empty native skin generation and DD /res/* 404s. Old stopped container `tgs-before-webclient-20261026` retained, restart=no. Its full inspect backup /root/webclient-test/tgs-before-webclient-20261026.json is mode0600; do not print it.
- Main config /home/tgs/tgs_instances/darkparadise/Configuration/GameStaticFiles/config/config.txt has WEB_GUEST_LOGIN enabled, GUEST_BAN already commented before us, LAUNCHER_REQUIRED preserved. Backup config.txt.before-web-guests-20261026 mode0600.
- Native .so installed in Configuration/GameStaticFiles/libdpwebauth.so, linked into TGS deployments. Engine binaries on disk not patched.
- Old transient webclient-test-gw and webclient-paradise-probe-gw stopped. `webclient-paradise-probe` and `webclient-auth-probe` containers stopped. Minimal `webclient-test-dd` port7790 still runs (~38MB), useful as 32bit gcc builder.

## Repository / TGS builds

- Remote repository /home/tgs/tgs_instances/darkparadise/Repository originally clean at d42ab410fa2cda14f537790da177d2630749001b, master220 with test merges already in commit. This revision differs from local HEAD; do not replace the remote repo with the entire local tree.
- Created SERVER-LOCAL branch codex/browser-guest-auth based on d42, applied only our diff. No GitHub push.
- Server commits cbe171806f0b84db603637f9711f8588a71047ad (auth + DM + helpers), cac4a8a6ddd074e9ff06e31b24a5c6e0350be82b (generated helpers.min.js).
- TGS reference now codex/browser-guest-auth. Main compile 172 directory e680a4e7-98fe-47bf-a82a-e1f0f8542881, SHA cac4a8a6...; 0 errors, 3 existing #warn warnings. Previous compile171 directory1ba2e7e1-bc29-4cce-8e90-e1cf81422ba5. Old original compile170 directory69440e65-8365-4b1e-929b-25dcb3a220d6 may have been pruned by TGS; Game/Live remains.
- Runtime JS source and local tools are newer than committed server code. Server Repository gateway.mjs and smoke_test.py have uncommitted updates; patch.mjs/README may be stale there. Before final deployment sync only our changes and record them. Existing deployment script expects master220, so ordinary future CI deploy will reject this local codex ref until reconciled. Preserve original test-merge content.

## API helper, safe operations

/root/webclient-test/dp-tgs-web-maint.py imports /usr/local/libexec/darkparadise-deploy as a module, uses its TgsClient and credential config, logs in fresh each invocation. Commands:

`python3 .../dp-tgs-web-maint.py status|job ID|compile|web|start|stop|checkout REF`

Routes: GET /DreamDaemon; POST /DreamDaemon {allowWebClient:true}; PUT /DreamDaemon {} starts watchdog; DELETE stops it; PUT /DreamMaker {} compiles; GET /Job/id; POST /Repository {reference,updateFromOrigin:false} checkout. `status` prints compact build metadata, no credentials. Last start job1123 succeeded. Job1121 built compile172. Main currently running; don't stop it merely to inspect.

## Local changes

Tracked DM/config:
- code/controllers/configuration/entries/config.dm: locked flag web_guest_login.
- code/game/world.dm: after load_configuration call CALL_EXT('./libdpwebauth.so','initialize')('data/web-auth.sock'); on missing/wrong adapter turn flag off and log.
- code/modules/client/client_procs.dm: allow connection==web only when flag enabled; is_connecting_from_localhost returns FALSE for web, preventing proxy localhost admin escalation.
- code/modules/client/launcher_link.dm: web guests exempt from launcher-required rejection when flag enabled; desktop launcher policy preserved.
- config/example/config.txt: documents new flag only.

TGUI:
- tgui/packages/tgui-setup/helpers.js detects same-origin parent.byond.skin and forwards Topic/winset/winget through web client.
- tgui/public/helpers.min.js rebuilt and deployed in compile172. IMPORTANT: ordinary Rspack tgui:build does NOT rebuild this file! Run `bun run build:helpers` from tgui/packages/tgui-setup, using local tools/bootstrap/.cache/bun-v1.3.5-x64/bun.exe (relative ../../../tools/... from package dir). Bun absent PATH. Rspack build already passed.
- Current helpers source uses window.byond.topic(query.join('&')). Runtime gateway TEMPORARILY replaces this minified expression with webClient.fn.topic(query.join('&')) to bypass stock iframe handshake while diagnosing. This experiment queues Topics but has NOT fixed gameplay. Do not cement it as a proven fix.

Untracked tools/webclient/ includes gateway.mjs, patch.mjs, tickets.mjs/tests, browser-bridge.test.mjs, native-auth.c, smoke_test.py, README.md and public/self.html, index.html, bridge.js. Keep all of them.

## Native adapter design and limitations

Linux x86 BYOND516.1682 only, libbyond.so GNU BuildID e9cdd7c77f6ceac5c3ac42b6f5574f388a969bde. In-memory hooks at offsets3f2b80 (web key handler) and3f2101 (guest seed call). Exact build ID + original bytes checked, unsupported build rejected. No hub emulator, closed hub protocol implementation or BYOND account impersonation.

Only web connection bit4, state5, dpweb-v1: prefix handled. Other formats and DreamSeeker use original function. Random128bit ticket one-use60sec, bounded4096, consumed via Unix socket0600. Returned identity always guest. Hook assigns connection username +0x38, webid +0x2f8, state6, invokes complete_login(base+3f1e90)(1,guest,id). Connection id from client+0x55c, find_connection base+405c60. TLS guest seed override produces distinct Guest-W keys and CIDs for users behind the gateway.

Actual player IP is in the ticket authority, but engine still sees proxy127.0.0.1. An earlier attempt to rewrite connection peer IP broke resource download authorization and was removed. Production IP bans/logging still need proper integration. Web localhost auto-admin has been disabled in DM. README explicitly documents this limitation. Do not pretend this is a documented BYOND setting or official provider.

Build adapter using existing minimal container:
`docker exec webclient-test-dd gcc -m32 -shared -fPIC -O2 -Wall -Wextra -Werror -o /world/libdpwebauth.so /world/native-auth.c -ldl`
Host source /root/webclient-test/world/native-auth.c, volume /root/webclient-test/world. Copy .so to GameStaticFiles only with planned DD restart. Do not replace running loaded libraries blindly.

## Gateway patches and temporary diagnostics left in place

- Patches stock HTTP URLs to location.origin + __dpNative; WS uses correct ws/wss +host+path.
- Browser message origin must compare ONLY location.origin, not base path. Fixed dedicated rule before general URL replacement. Generated HTML base needs trailing slash. /html/* base rewritten to /webtest/.
- Own-origin parent key messaging; actual message26 untouched by gateway/native consumes it.
- UTF8 decode getString and outgoing bridge encoder adjusting byte lengths, including >=65535 prefixed-string boundary. Russian welcome text now correct.
- Entire old bulk resource preload disabled; resources load on use. Avoids legacy WOFF2 OpenType crashes. Queue continues on failed downloads.
- Server startup without BYOND_SYSTEM can still load JS if gateway serves files from BYOND_WEB_DIR, but native skins remain blank. Actual DD env was fixed too.
- Error overlay and Retry prevent silent endless spinner; handles ticket failure, disconnect, download idle timeout. Header 'В игре' currently means stock client ready, not proven actual gameplay; consider 'Подключено' to avoid overclaiming.
- TEMPORARY instrumentation remains in gateway.mjs /html/* response: injects DOMContentLoaded beacon (isByond,hasSkin,parentOrigin) and error beacon; replaces Topic call as above. Diagnostics showed isByond=true,hasSkin=true for TGUI0/1/4/5. HTML2/3 are asset windows, not TGUI.
- TEMPORARY patch.mjs rule `temporary Topic diagnostics` adds P.print('Browser Topic queued') inside native sendTopicMessage. Last logs prove this function is called. Remove temporary instrumentation once issue resolved.
- Old vendor JS saved locally %TEMP%/dp-vendor.js and remotely /root/webclient-test/vendor.js. Be careful rg long minified lines: huge output. Served UI snapshots %TEMP%/dp-main-ui4.html and remote main-ui4.html. These are code/debug artifacts, not instructions.

## Tests and evidence

- Local DM compilation after DM+helpers source: 0errors,3 existing warnings. TGS compile172 after generated helpers: same.
- dreamchecker: Found0diagnostics.
- Python3.11 identical_variables passed, most recent48.3s. check_icons and check_ru_names previously passed. check_grep passed, check_grep2 had existing unrelated failures (manual macros/quoted resource paths etc); do not claim all linters green.
- node --test tools/webclient/*.test.mjs: local4pass,1Unix socket skip. Linux remote5/5 passed.
- Production real DD smoke succeeded: 2distinct guests, replay+unissued tickets rejected. Also passed with /webtest base after fixing Origin header to scheme://host (not a URL with path). Does not prove gameplay; it only checks message26 admission.
- Browser reaches native skin, lobby art, Russian game messages, but fancy chat fails and stat stays loading, then Quit8. Most recent browser is disconnected with Retry. Do not use that screenshot as completion proof.
- Main game logs under Configuration/GameStaticFiles/data/logs/2026/10-October/26-Monday/round-698/. tgui.log shows initializes but no known readiness. game/runtime logs had spritesheet missing-file errors even though files exist in Game/Live; investigate only if tied to current blockage. Main initial maps finished, so current issue is not just server boot time.
- Native stdout log /home/tgs/tgs_instances/darkparadise/Diagnostics/DreamDaemonLogs/2026-10-26/server-utc-2026-10-26-02-11-42.log shows adapter enabled, DB connected, ticket accept/reject.

## Browser tooling

Persistent cua_repl variables gameTab (tab1 now http://92.63.189.21:7779/), secondGameTab (tab2 older mini test), selected IAB browser id2. Call cua.rewriteDocumentation before continuing after compaction. Use native AX/screenshot wrappers or documented locators; read-only DOM evaluate only, no hidden app state or arbitrary browser runtime calls. Prefer no more browser actions today. Mark gameTab handoff if preserving it. Final screenshot proof still needed when actual gameplay is working.

## Resume priorities

1. Reconfirm main online and read this handoff; do not repeat auth research or previously failed client.authenticate=0/loopback/hub-address none/guessed token approaches.
2. Diagnose why outgoing Topic/heartbeat/resource-ready traffic doesn't activate live game despite valid guest admission and logged-in JS. Instrument only bounded non-sensitive IDs/types, never tokens/credentials or complete Topic payloads.
3. Make TGUI and lobby buttons work, enter/observe actual map, keep connection stable beyond Quit8 interval; verify actual main round by query.
4. Resolve real IP moderation integration or clearly state limitation; current native .address is proxy.
5. Remove temporary diagnostics, synchronize local/server code, rebuild generated helpers if edited, compile DM only if necessary, then test main and HTTPS path. Keep rollback artifacts.
6. Reconcile server-local codex branch with normal master220 deployment; no GitHub push/PR was requested yet. Do not publish or claim completed crossplay before verification.
