# Musk WebAI P0 UI Redesign Execution Log

## Status Legend

- `pending`: not started.
- `in_progress`: currently being worked on.
- `done`: completed locally or verified.
- `blocked`: cannot proceed without external state changing.

## Execution Steps

| Step | Status | Action | Result |
|---|---|---|---|
| 0.1 | done | Confirm P0 scope | Scope is visual polish only: typography, sidebar, chat report layout, thinking block, composer, and light login polish. |
| 0.2 | done | Inspect workspace shape | This workspace is a deployment and patch workspace, not the Open WebUI frontend source repo. |
| 0.3 | done | Read existing patch files | Reviewed `runtime-sidebar-polish.sh`, `sidebar-css-fallback-patch.sh`, `hard-cache-bust-workspace-tabs.py`, and `docs/DEVELOPMENT.md`. |
| 1.1 | done | Check production container health over SSH | SSH later recovered; `open-webui` reported `healthy`. |
| 1.2 | done | Back up production `brand-patch.sh` | Backed up to `/app/backend/data/brand-patch.sh.bak.20260530212415`. |
| 1.3 | done | Record production build version | Previous frontend version was `4e3aa26b4d5678a527ab53ae685acbec60a38897`. |
| 1.4 | partial | Capture production before screenshots | Initial browser/login state was observed earlier; full authenticated chat baseline was not available because the browser was not logged in. |
| 2.1 | done | Create unified UI patch | Added `patches/musk-webai-ui-patch.sh`. |
| 2.2 | done | Merge sidebar/runtime concepts | Consolidated sidebar hiding, text replacement, typography, chat, thinking, composer, and login polish into one incremental patch. |
| 2.3 | done | Add idempotent cleanup | Patch removes older `musk-webai-ui-polish`, `musk-webai-sidebar-polish`, `musk-webai-ui-runtime`, and `musk-webai-runtime-polish` before reinjecting. |
| 2.4 | done | Preserve existing branding patch | New patch is additive and does not replace the current production `brand-patch.sh`. |
| 2.5 | done | Reduce immutable JS rewriting | P0 uses CSS and lightweight runtime DOM tagging, not JS chunk rewrites. |
| 3.1 | done | Define typography tokens | Added controlled typography for body, Markdown headings, thinking, citations, code, tables, sidebar, and inputs. |
| 3.2 | done | Sidebar polish | Added shallow surface, hover, selected item, brand/menu sizing, and new-chat button treatment. |
| 3.3 | done | Chat reading layout | Markdown/prose max width, line height, heading hierarchy, lists, tables, blockquotes, code, and citations are covered. |
| 3.4 | done | Thinking block de-emphasis | Runtime marks thinking/reasoning labels and blocks; CSS lowers visual weight and size. |
| 3.5 | done | User message polish | Runtime marks likely user message bubbles; CSS applies softer blue bubble treatment. |
| 3.6 | done | Composer polish | `#chat-input` and its closest form get controlled typography, radius, border, shadow, and focus treatment. |
| 3.7 | done | Login/form polish | Password form width and input/button typography are controlled. |
| 3.8 | done | Mobile constraints | Added mobile heading, prose, and composer constraints. |
| 4.1 | done | Inject stylesheet | Patch injects `<style id="musk-webai-ui-polish">` into `index.html` and `app.html`. |
| 4.2 | done | Inject runtime script | Patch injects `<script id="musk-webai-ui-runtime">` into `index.html` and `app.html`. |
| 4.3 | done | Runtime scope control | Runtime only handles text replacement, search hiding, composer marking, thinking marking, and likely user-message marking. |
| 4.4 | done | Cache bust and idempotence test | Patch updates `/app/build/_app/version.json` to `musk-webai-ui-<timestamp>` when present. Local simulation against a downloaded `index.html` ran twice with exactly one `musk-webai-ui-polish` and one `musk-webai-ui-runtime` block remaining. |
| 5.1 | done | Upload patch to production | Uploaded `patches/musk-webai-ui-patch.sh` to `/tmp/musk-webai-ui-patch.sh`. |
| 5.2 | done | Execute patch in production container | Executed inside `open-webui`; updated `/app/build/index.html` and `/app/build/_app/version.json`. |
| 5.3 | done | Check container health after deploy | Container remained `healthy`. |
| 5.4 | done | Hard-refresh WebAI | Browser loaded `http://152.32.172.162` with cache-busting query; frontend version is `musk-webai-ui-1780147617`. |
| 5.5 | partial | Screenshot verification | Login page renders with `musk-webai-ui` active. Authenticated chat page still needs a logged-in browser session to visually verify sidebars, conversation messages, and composer. |
| 5.6 | partial | Core function verification | HTTP/config and login page load verified. Authenticated flows such as model selection, sending, upload, and history still require a logged-in session. |
| 5.7 | done | Persist UI patch through future recreates | Installed `/app/backend/data/musk-webai-ui-patch.sh`, `/app/backend/data/musk-webai-ui-rollback.sh`, and appended the `MUSK_WEBAI_UI_PATCH` hook to `brand-patch.sh` at lines 1300-1304. |
| 6.4 | done | Update maintenance docs | Added P0 UI patch maintenance notes to `docs/DEVELOPMENT.md`. |
| 7.1 | done | Add deployment helper | Added `scripts/deploy-ui-patch.sh` for copy/apply/persistence flow once SSH works. |
| 7.2 | done | Add rollback patch | Added `patches/musk-webai-ui-rollback.sh` to remove only P0 UI style/runtime blocks and refresh frontend version. |
| 7.3 | done | Add local simulation helper | Added `scripts/simulate-ui-patch.sh`; it downloads current production HTML into `/private/tmp`, runs the patch twice, and verifies idempotence counts. |
| 7.4 | done | Add persistence helper | Added `scripts/persist-ui-patch-hook.sh` and used it for safer production persistence. |
| 8.1 | done | Apply P0.1 sidebar hierarchy | Production patch updated normal chat links to transparent list rows, hover to a light surface, and the active conversation to white background with blue dot. |
| 8.2 | done | Apply P0.2 home empty-state hierarchy | Home empty state title now changes from repeated model name to `今天要完成什么工作？`. |
| 8.3 | done | Apply P0.3 composer de-emphasis | Composer max width reduced to 820px on desktop, with lighter border/shadow. |
| 8.4 | done | Fix mobile model selector | Mobile model selector now shows the short label `模型` to avoid overlapping top-right controls. |

## Connectivity Diagnosis

Earlier blocked retry:

- HTTP on port 80 is reachable and returns `200 OK`.
- TCP port 22 is reachable.
- SSH sessions close before password authentication and no SSH banner is returned through `nc`.
- `ssh-keyscan -T 5 -p 22 152.32.172.162` also reports `Connection closed by remote host`.
- No production command has run during the failed attempts.

This points to an SSH entry/daemon policy issue, temporary connection protection, or server-side SSH service behavior before authentication rather than an application outage.

Later retry:

- `ssh-keyscan` returned the OpenSSH 8.7 banner and host keys.
- SSH password authentication succeeded.
- Production patch deployment and persistence completed.

## Production Verification

Current production frontend version:

```json
{"version": "musk-webai-ui-1780152119"}
```

HTTP index counts after deployment:

- `id="musk-webai-ui-polish"`: 1
- `id="musk-webai-ui-runtime"`: 1
- legacy `musk-webai-sidebar-polish` / `musk-webai-runtime-polish`: 0

Browser runtime checks:

- `document.documentElement.classList.contains("musk-webai-ui")`: `true`
- `#musk-webai-ui-polish`: 1
- `#musk-webai-ui-runtime`: 1
- legacy style/script ids: 0
- `body` font size: `15px`
- login route renders.
- authenticated conversation route renders.
- desktop conversation H1: `32px`; H2: `25px`; thinking block: `14.5px`.
- desktop composer width: `820px`.
- mobile composer width at 390px viewport: `370px`.
- mobile model selector uses the short label `模型`.
- home empty title: `今天要完成什么工作？`.

Production persistence:

- `/app/backend/data/musk-webai-ui-patch.sh` installed.
- `/app/backend/data/musk-webai-ui-rollback.sh` installed.
- `/app/backend/data/brand-patch.sh` contains `MUSK_WEBAI_UI_PATCH_BEGIN` / `MUSK_WEBAI_UI_PATCH_END`.

Verification screenshots:

- `/private/tmp/webai-p01-desktop-conversation.png`
- `/private/tmp/webai-p01-mobile-conversation.png`
- `/private/tmp/webai-p02-desktop-final.png`
- `/private/tmp/webai-p02-mobile-final.png`

## Local Simulation

The patch supports a test/staging build directory:

```sh
MUSK_WEBAI_BUILD_DIR=/private/tmp/musk-webai-ui-test sh patches/musk-webai-ui-patch.sh
```

Local simulation used the current production HTML copied to `/private/tmp/musk-webai-ui-test.*/index.html`. The patch was run twice; the second run made no extra injection. Counts after the second run:

- `id="musk-webai-ui-polish"`: 1
- `id="musk-webai-ui-runtime"`: 1
- legacy `musk-webai-sidebar-polish` / `musk-webai-runtime-polish`: 0

Reusable helper:

```sh
scripts/simulate-ui-patch.sh
```

## Deployment Path When SSH Recovers

From a local checkout, copy the patch to the production host and execute it inside the container:

```sh
scripts/deploy-ui-patch.sh
```

To also persist the patch through future container recreates:

```sh
PERSIST_UI_PATCH=true scripts/deploy-ui-patch.sh
```

If already on the production host with the patch file available:

```sh
docker cp patches/musk-webai-ui-patch.sh open-webui:/tmp/musk-webai-ui-patch.sh
docker exec open-webui sh /tmp/musk-webai-ui-patch.sh
docker inspect -f '{{.State.Health.Status}}' open-webui
```

For persistence across container recreates:

```sh
cp -f patches/musk-webai-ui-patch.sh /var/lib/docker/volumes/open-webui_open-webui/_data/musk-webai-ui-patch.sh
```

Then call this near the end of `/app/backend/data/brand-patch.sh`:

```sh
sh /app/backend/data/musk-webai-ui-patch.sh
```

Rollback the P0 UI layer only:

```sh
docker cp patches/musk-webai-ui-rollback.sh open-webui:/tmp/musk-webai-ui-rollback.sh
docker exec open-webui sh /tmp/musk-webai-ui-rollback.sh
```

## 2026-05-30 P0.3 Conversation Polish And State Guardrails

Implemented after desktop conversation, homepage, legal chat, and connection-status walkthroughs.

| Step | Status | Item | Notes |
| --- | --- | --- | --- |
| 9.1 | done | Composer no longer covers final content | `#messages-container` now reserves `var(--musk-composer-height) + 32px`; browser verification showed `padding-bottom: 150px` with a `118px` composer. |
| 9.2 | done | Reduce Composer double-container weight | The outer composer keeps the single border/shadow; `#message-input-container` background, border, and shadow are neutralized. |
| 9.3 | done | De-emphasize table actions | Table shells are marked precisely from real `table` parents; `预览 / 下载 Excel` buttons are light by default and strengthen on hover. |
| 9.4 | done | Suggestions as task entries | Homepage suggestion buttons are marked as lightweight task entries with `15px` title and `12.5px` description. |
| 9.5 | done | Sidebar active state separation | Current conversation indicator changed from a blue dot to a `3px x 16px` left blue line. |
| 9.6 | done | Connection notice de-noise | Reconnect/disconnect notices are marked only on notice surfaces and repeated notices inside 15 seconds are hidden. |
| 9.7 | done | Running/loading watchdog | Visible stop-button generations are tracked per route and auto-stop after 5 minutes; route loading shows a 5s slow notice and 15s retry/error notice. |

Production verification:

- Frontend version: `musk-webai-ui-1780154947`.
- `id="musk-webai-ui-polish"`: 1.
- `id="musk-webai-ui-runtime"`: 1.
- legacy `musk-webai-sidebar-polish` / `musk-webai-runtime-polish`: 0.
- Runtime JavaScript parsed with `new Function(...)`.
- Container health: `healthy`.
- Persistent patch: `/app/backend/data/musk-webai-ui-patch.sh`.
- Persistent hook: `/app/backend/data/brand-patch.sh` still contains `MUSK_WEBAI_UI_PATCH_BEGIN`.
- Current `brand-patch.sh` backup: `/app/backend/data/brand-patch.sh.bak.20260530233649`.

Known limitation:

- The 5-minute auto-stop is a frontend guardrail based on the visible stop button. A backend/server-side timeout should still be added in the real Open WebUI request pipeline when this workspace moves from runtime patching to source-level customization.

## 2026-05-30 P0.4 Connection Stale Recovery

Implemented after user `isunnychoi` reported frequent `断开连接 / 重新连接` prompts where auto reconnect sometimes did not recover.

| Step | Status | Item | Notes |
| --- | --- | --- | --- |
| 10.1 | done | Check server health | `open-webui` was healthy, `RestartCount=0`, `OOMKilled=false`, memory about `1.112GiB / 3.571GiB`. |
| 10.2 | done | Check local server path | On the server, `127.0.0.1/api/config` returned `200` with `enable_websocket: true`; port `80` was published to container `8080`. |
| 10.3 | done | Inspect recent logs | No backend WebSocket crash or container restart was found in the recent log sample. |
| 10.4 | done | Add connection stale recovery | Runtime now watches persistent connection-lost notices. After 8s it shows a recovery hint; after 18s it probes `/api/version`. If HTTP is reachable and there is no draft or active generation, it refreshes the current route once with cache busting. |
| 10.5 | done | Protect active work | If a draft exists or a generation is running, auto-refresh is skipped and a `刷新连接` button is shown instead. |
| 10.6 | done | Deploy and verify | Production version is `musk-webai-ui-1780156437`; style/runtime counts remain `1/1`, legacy count `0`, runtime JS parses successfully, browser console had no new errors on homepage load. |

Current assessment:

- The issue is most likely a stale frontend socket/client-network recovery problem rather than a container crash.
- The UI now recovers automatically in safe states and gives users an explicit manual recovery action when auto-refresh could lose work.
- A deeper source-level fix would inspect the Open WebUI socket client and reconnect backoff behavior directly in the frontend source repo.

## 2026-05-30 P0.5 Connection Recovery Hardening

Continued after `isunnychoi` reported that disconnect/reconnect prompts could stay visible and sometimes only recovered after clicking elsewhere.

| Step | Status | Item | Notes |
| --- | --- | --- | --- |
| 11.1 | done | Reassess failure mode | The symptom points to a stale frontend socket/router state: the page remains alive and HTTP can be reachable, but the native reconnect loop does not always recover. |
| 11.2 | done | Add client reconnect nudges | After a persistent connection notice lasts 4s, runtime dispatches browser `online`, `focus`, and `visibilitychange` events to wake reconnect handlers. |
| 11.3 | done | Add soft route rebuild | After 12s, runtime updates the current route with a cache-bust query and dispatches `popstate`, matching the user-observed behavior that clicking another route can recover the page. |
| 11.4 | done | Safer hard refresh | After 22s, runtime probes `/api/version`; if HTTP is reachable and no generation is running, it refreshes the current page. Draft text is temporarily stored in `sessionStorage` and restored after reload. |
| 11.5 | done | Keep active generation protected | If a stop button is visible or refreshes are happening too frequently, runtime keeps the manual `刷新连接` action instead of forcing a reload loop. |
| 11.6 | done | Deploy and verify | Production version is `musk-webai-ui-1780157083`; style/runtime counts are `1/1`, legacy count `0`, runtime JS parses successfully, and browser homepage load had no console errors. |

Current assessment:

- This is a stronger runtime workaround for the user-facing reconnect loop.
- The source-level follow-up remains the same: inspect Open WebUI's actual socket/reconnect client and tune its retry/backoff or failure-state clearing directly when the frontend source repo is available.

## 2026-05-31 P0.6 Connection Root-Cause Investigation

Started after the previous runtime mitigation was challenged as a patch rather than a root-cause fix.

| Step | Status | Item | Evidence |
| --- | --- | --- | --- |
| 12.1 | done | Check container health | `open-webui` remained `healthy`; `RestartCount=0`; `OOMKilled=false`; memory about `1.11GiB / 3.571GiB`. |
| 12.2 | done | Check deployment chain | Host port `80` is served directly by `docker-proxy` to container `8080`; no nginx/caddy reverse proxy was found on port `80`. |
| 12.3 | done | Check Open WebUI versioning | Container image is `ghcr.io/open-webui/open-webui:main`; app config reports Open WebUI `0.9.5`; image revision is `3660bc00fd807deced3400a63bfa6db47811a3bb`. |
| 12.4 | done | Check socket server config | Backend `socketio.AsyncServer` uses `transports=['websocket']` when `ENABLE_WEBSOCKET_SUPPORT=True`; current env has `ENABLE_WEBSOCKET_SUPPORT=True`, `ping_interval=25`, `ping_timeout=20`. |
| 12.5 | done | Verify handshake | Internal and external `/ws/socket.io/?EIO=4&transport=websocket` handshakes return `101 Switching Protocols`; polling returns `400 Invalid transport`, which matches websocket-only mode. |
| 12.6 | done | Inspect frontend socket setup | Source map shows `setupSocket(enableWebsocket)` uses `transports: enableWebsocket ? ['websocket'] : ['polling', 'websocket']`; `/api/config` currently returns `enable_websocket: true`, so the browser runs websocket-only. |
| 12.7 | done | Interpret user symptom | `isunnychoi` seeing repeated disconnect/reconnect, sometimes recovering after clicking elsewhere, is consistent with a stale websocket-only client path over `ws://IP:80`, not a backend crash. Server logs also show orphaned socket sessions being reaped after missed heartbeats. |

Root-cause assessment:

- The strongest current root cause is not the visual toast itself. It is the production transport choice: direct `ws://` WebSocket over bare IP/port 80 with no polling fallback and no HTTPS/WSS reverse proxy.
- Because both frontend and backend are in websocket-only mode, any client/network path that intermittently kills WebSocket has no HTTP polling fallback.
- The runtime patch should be treated as a temporary mitigation only.

Recommended fix order:

1. For immediate stability, set `ENABLE_WEBSOCKET_SUPPORT=false` and restart Open WebUI so clients use polling-first transport. This trades efficiency for reliability and is suitable while the site is served as `http://152.32.172.162`.
2. For production-grade realtime, add a domain + HTTPS/WSS reverse proxy with explicit WebSocket upgrade headers, long read/send timeouts, and proxy buffering disabled; then turn websocket support back on.
3. Pin the Open WebUI image to a release tag instead of `main` before further production hardening.
4. Temporarily enable Socket.IO/Engine.IO logging only during a reproduction window if the issue persists after the transport change.

## 2026-05-31 P0.7 Polling Transport Fix

Executed the immediate stability fix from P0.6.

| Step | Status | Item | Evidence |
| --- | --- | --- | --- |
| 13.1 | done | Backup compose | `/opt/open-webui/docker-compose.yml` was backed up as `docker-compose.yml.bak.websocket.<timestamp>` before editing. |
| 13.2 | done | Disable websocket-only mode | Added `ENABLE_WEBSOCKET_SUPPORT: "${ENABLE_WEBSOCKET_SUPPORT:-false}"` under the Open WebUI environment block. |
| 13.3 | done | Restart service | `docker compose up -d open-webui` recreated the container; final health was `healthy`, `RestartCount=0`, `OOMKilled=false`. |
| 13.4 | done | Verify config | `/api/config` now returns `features.enable_websocket=false`. |
| 13.5 | done | Verify transport | Internal Socket.IO polling probe returned `200 OK`; websocket probe returned `403 Forbidden`, confirming websocket-only mode is closed. Server logs showed real client `transport=polling` requests returning `200`. |
| 13.6 | done | Restore UI runtime after restart | Re-applied the latest UI patch because the restart initially served legacy injected HTML; production UI version became `musk-webai-ui-1780159013`, style/runtime counts were `1/1`, legacy count `0`, and runtime JS parsed successfully. |
| 13.7 | done | Browser verification | Browser loaded `Musk WebAI` with `musk-webai-ui` class active, no reconnect/disconnect notices, and no console errors. |

Remaining production hardening:

- Add a domain and HTTPS/WSS reverse proxy before re-enabling websocket mode.
- Pin `ghcr.io/open-webui/open-webui:main` to a stable release tag.
- Fix startup persistence so the UI patch is applied after Open WebUI's build files are available, not only before `start.sh`.

## 2026-05-31 P0.8 Startup Persistence Fix

Executed after P0.7 revealed that a container restart initially served legacy injected HTML until the UI patch was manually re-applied.

| Step | Status | Item | Evidence |
| --- | --- | --- | --- |
| 14.1 | done | Inspect existing startup hook | Compose still ran `sh /app/backend/data/brand-patch.sh; bash start.sh`, so patching happened only before the server process. |
| 14.2 | done | Find legacy brand patch issue | `brand-patch.sh` currently fails syntax validation at line 315 due to corrupted historical self-persisted blocks. The new startup flow avoids calling it. |
| 14.3 | done | Add startup wrapper | Installed `/app/backend/data/start-webai-with-patches.sh` and updated compose to `sh /app/backend/data/start-webai-with-patches.sh`. |
| 14.4 | done | Delay UI patch after startup | Wrapper applies `/app/backend/data/musk-webai-ui-patch.sh` at 0s, 3s, 8s, 20s, and 45s, covering late frontend file writes. |
| 14.5 | done | Restart verification | `docker compose restart open-webui` returned `healthy`; after delayed patching, version was `musk-webai-ui-1780161775`, style/runtime counts were `1/1`, and legacy count was `0`. |
| 14.6 | done | Browser verification | Browser load showed `musk-webai-ui` active, no reconnect/disconnect notices, and no console errors. |

Current operational note:

- Do not run `/app/backend/data/brand-patch.sh` manually until it is cleaned or replaced; it can reintroduce legacy injections before failing.
- The safe persistent startup path is now the new wrapper plus the standalone `musk-webai-ui-patch.sh`.

## 2026-05-31 P0.9 Safe Brand Patch Replacement

Executed after P0.8 confirmed the historical `brand-patch.sh` was corrupted and could reintroduce legacy injections if run manually.

| Step | Status | Item | Evidence |
| --- | --- | --- | --- |
| 15.1 | done | Create safe replacement | Added `scripts/brand-patch-safe.sh`; it only performs stable brand/link text replacement and then delegates to `/app/backend/data/musk-webai-ui-patch.sh`. |
| 15.2 | done | Local syntax check | `sh -n scripts/brand-patch-safe.sh` passed. |
| 15.3 | done | Backup and replace production script | Replaced `/app/backend/data/brand-patch.sh`; backup saved as `/app/backend/data/brand-patch.sh.bak.safe.20260531013200`. |
| 15.4 | done | Production dry run | New `brand-patch.sh` passed `sh -n`; dry run reported `safe_brand_patch_changed=0` and kept `style=1 runtime=1 legacy=0`. |
| 15.5 | done | Restart verification | After `docker compose restart open-webui`, config stayed `enable_websocket=false`; version became `musk-webai-ui-1780162747`; counts stayed `style=1 runtime=1 legacy=0`. |
| 15.6 | done | Browser verification | Browser loaded `Musk WebAI` with `musk-webai-ui` active, no reconnect/disconnect notices, and no console errors. |

Current operational note:

- `/app/backend/data/brand-patch.sh` is now safe to run; it no longer self-modifies and no longer carries historical brittle chunk patches.
- The startup wrapper still handles normal restart persistence; `brand-patch.sh` is now a clean manual/compatibility entrypoint.
