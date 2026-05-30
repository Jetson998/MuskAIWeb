# Musk WebAI Development And Operations Notes

## Repository Contents

This repository stores the local deployment scaffold and documentation for the Musk WebAI self-hosted Open WebUI instance.

Current files:

- `docker-compose.yml`: local/minimal Open WebUI Compose template.
- `README.md`: quick start and documentation index.
- `docs/PRODUCT.md`: product behavior and user-facing configuration.
- `docs/DEVELOPMENT.md`: implementation, deployment, and maintenance notes.

## Production Deployment Snapshot

Production server:

```text
Host: 152.32.172.162
OS: CentOS Stream 9
App URL: http://152.32.172.162
Compose path: /opt/open-webui
Container name: open-webui
Image: ghcr.io/open-webui/open-webui:main
Port mapping: 80:8080
Data volume: open-webui_open-webui
Data path in container: /app/backend/data
```

Do not store server passwords, API keys, or provider secrets in this repository.

## Production Compose Notes

The production Compose file is located on the server:

```sh
cd /opt/open-webui
```

Important production behavior:

- `WEBUI_NAME` is set to `Musk WebAI`.
- `ENABLE_PERSISTENT_CONFIG=false` is used so selected UI defaults can be controlled from environment variables.
- `DEFAULT_PROMPT_SUGGESTIONS` contains the three homepage starters.
- The container command runs the startup branding patch before `start.sh`.

The production command pattern is:

```yaml
command: >-
  sh -lc "sh /app/backend/data/brand-patch.sh; bash start.sh"
```

## Branding Patch

The runtime branding patch is stored in the Open WebUI data volume:

```text
/var/lib/docker/volumes/open-webui_open-webui/_data/brand-patch.sh
```

Inside the container it is available as:

```text
/app/backend/data/brand-patch.sh
```

The patch currently handles:

- Replacing visible Open WebUI branding strings with Musk WebAI.
- Preventing backend `WEBUI_NAME` from appending `(Open WebUI)`.
- Replacing Open WebUI-related frontend links with `http://www.muskapis.com`.
- Disabling the `/workspace/models` community discovery block.
- Clearing model-page community discovery text.

After image upgrades, restart the container so the patch re-applies to the fresh image filesystem.

## P0 UI Polish Patch

The first front-end redesign pass is maintained as a separate incremental patch:

```text
patches/musk-webai-ui-patch.sh
patches/musk-webai-ui-rollback.sh
```

This patch is intentionally limited to the P0 visual layer. It injects one stylesheet and one small runtime script into `/app/build/index.html` and `/app/build/app.html`:

```text
<style id="musk-webai-ui-polish">
<script id="musk-webai-ui-runtime">
```

The script is idempotent. Before injection it removes older `musk-webai-ui-polish`, `musk-webai-sidebar-polish`, `musk-webai-ui-runtime`, and `musk-webai-runtime-polish` blocks so repeated runs do not stack CSS or observers.

By default the patch targets `/app/build`. For local or staging tests, override the build directory:

```sh
MUSK_WEBAI_BUILD_DIR=/tmp/mock-build sh patches/musk-webai-ui-patch.sh
```

To run the same idempotence check against a temporary copy of the current production HTML:

```sh
scripts/simulate-ui-patch.sh
```

P0 scope:

- Typography tokens for chat reports, headings, thinking/reasoning blocks, sidebars, inputs, code blocks, tables, and citations.
- Sidebar surface, menu hover states, current-item treatment, and new-chat button polish.
- Chat report layout with a controlled reading width and calmer Markdown hierarchy.
- Thinking/reasoning visual de-emphasis so formal answers stay primary.
- Bottom composer polish around `#chat-input`.
- Light login/form polish.
- Mobile typography and composer constraints.

Deployment helper:

```sh
scripts/deploy-ui-patch.sh
scripts/persist-ui-patch-hook.sh
```

Useful environment variables:

```text
WEBAI_HOST=152.32.172.162
WEBAI_USER=root
WEBAI_CONTAINER=open-webui
PERSIST_UI_PATCH=false
```

Set `PERSIST_UI_PATCH=true` only when the patch should also be called from `/app/backend/data/brand-patch.sh` on future container recreates.

Manual deployment options:

1. From a local checkout, copy it to the production host and run it inside the container after the existing branding patch:

```sh
scp patches/musk-webai-ui-patch.sh root@152.32.172.162:/tmp/musk-webai-ui-patch.sh
ssh root@152.32.172.162 'docker cp /tmp/musk-webai-ui-patch.sh open-webui:/tmp/musk-webai-ui-patch.sh && docker exec open-webui sh /tmp/musk-webai-ui-patch.sh'
```

If already on the production host with the patch file available:

```sh
docker cp patches/musk-webai-ui-patch.sh open-webui:/tmp/musk-webai-ui-patch.sh
docker exec open-webui sh /tmp/musk-webai-ui-patch.sh
```

2. For persistence across container recreates, copy it into the data volume and call it from `/app/backend/data/brand-patch.sh` after the existing branding logic:

```sh
sh /app/backend/data/musk-webai-ui-patch.sh
```

Rollback removes only the P0 UI style/runtime blocks and refreshes the frontend version:

```sh
docker cp patches/musk-webai-ui-rollback.sh open-webui:/tmp/musk-webai-ui-rollback.sh
docker exec open-webui sh /tmp/musk-webai-ui-rollback.sh
```

Current production P0 deployment:

```text
Frontend version: musk-webai-ui-1780159013
brand-patch backup: /app/backend/data/brand-patch.sh.bak.20260530233649
Persistent hook: /app/backend/data/brand-patch.sh lines 1300-1304
Rollback helper: /app/backend/data/musk-webai-ui-rollback.sh
```

Keep this patch CSS-first. Only add runtime JavaScript for text replacement, hiding legacy entries, or lightweight DOM class tagging. Avoid direct immutable JS chunk rewrites unless CSS/runtime hooks cannot solve the issue.

Latest UI runtime guardrails:

- Composer height is measured in the browser and written to `--musk-composer-height`.
- `#messages-container` reserves composer height plus breathing room to prevent final content from being hidden.
- Reconnect/disconnect notices are de-duplicated for 15 seconds on toast/status surfaces.
- A visible generation stop button starts a per-route 5-minute watchdog; after timeout the UI attempts to stop and shows a retry hint.
- Persistent connection-lost notices trigger a stale-connection recovery flow: after 4 seconds wake client reconnect listeners, after 8 seconds show a recovery hint, after 12 seconds rebuild the current route, and after 22 seconds probe `/api/version`; when HTTP is reachable and no generation is running, auto-refresh once with draft text preserved in `sessionStorage`, otherwise show a `刷新连接` action.

Root-cause note for reconnect/disconnect reports:

- Current production serves Open WebUI directly as `http://152.32.172.162` through Docker port `80:8080`, without an HTTPS/WSS reverse proxy.
- Open WebUI currently reports `enable_websocket: true`; backend accepts websocket transport only, and frontend source map shows it uses `transports: ['websocket']` in that mode.
- Internal and external WebSocket handshakes return `101 Switching Protocols`, while polling returns `400 Invalid transport`; this is expected in websocket-only mode.
- The more durable fix is configuration/infrastructure, not runtime UI patching: either disable websocket support temporarily for polling-first reliability on the bare-IP HTTP deployment, or add domain + HTTPS/WSS reverse proxy with proper upgrade headers and long timeouts before keeping websocket-only behavior.

Current production transport:

- `ENABLE_WEBSOCKET_SUPPORT=false` is set in `/opt/open-webui/docker-compose.yml`.
- `/api/config` returns `features.enable_websocket=false`.
- Socket.IO now accepts polling transport and rejects direct websocket transport.
- The UI patch had to be re-applied after the container restart; the startup hook should be revisited so future restarts keep the latest UI patch without a manual re-apply.

## Model Optimization Layer

The model optimization work should be developed as a source-level module, not as a production runtime UI patch.

Reference documents:

- `docs/MODEL_OPTIMIZATION_TECH_SPEC.md`
- `docs/MODEL_OPTIMIZATION_EXECUTION.md`

Current priority:

```text
P0: Generation Integrity Guard
```

P0 scope:

- Record generation lifecycle data: `finish_reason`, usage, stream state, saved text length.
- Filter or mark empty assistant messages.
- Detect truncated answers and write `generation_status=incomplete`.
- Add a continuation endpoint and frontend `继续生成` entry.
- Dynamically increase output budget for long tasks when the user has not explicitly overridden max tokens.

This work depends on the real Open WebUI source tree. The current repository is only the deployment and runtime patch workspace, so it should not be used to hot-patch backend generation logic in production.

## Homepage Starter Prompts

Homepage starters are controlled through the production `DEFAULT_PROMPT_SUGGESTIONS` environment variable in `/opt/open-webui/docker-compose.yml`.

Current order:

1. `腾讯控股深度拆解`
2. `全球AI项目雷达`
3. `采购合同风险体检`

When updating starter prompts:

1. Back up the production Compose file.
2. Edit `DEFAULT_PROMPT_SUGGESTIONS`.
3. Recreate the container so environment variables are reloaded.
4. Verify the container is healthy and the prompt list is correct.

Example maintenance flow:

```sh
cd /opt/open-webui
cp -f docker-compose.yml docker-compose.yml.bak.$(date +%Y%m%d%H%M%S)
docker compose stop open-webui
docker compose up -d --force-recreate --remove-orphans
```

Verify:

```sh
docker inspect -f '{{.State.Health.Status}}' open-webui
docker exec open-webui sh -lc 'python3 - <<'"'"'PY'"'"'
import os, json
data = json.loads(os.environ.get("DEFAULT_PROMPT_SUGGESTIONS", "[]"))
print("COUNT", len(data))
for item in data:
    print(" / ".join(item["title"]))
PY'
```

Expected output should include exactly three starters:

```text
COUNT 3
腾讯控股深度拆解 / 财报、回购与增长变量一页看懂
全球AI项目雷达 / 从开发者热榜发现早期机会
采购合同风险体检 / 定位风险、改条款、给谈判话术
```

## Image Generation Configuration

Open WebUI must route image-only models through its Images backend. Do not select `gpt-image-2` as the active chat model; the provider will reject chat requests with:

```text
model gpt-image-2 is only supported on /v1/images/generations and /v1/images/edits
```

Use a normal text model in the chat selector, then configure image generation with:

```yaml
ENABLE_IMAGE_GENERATION: "true"
IMAGE_GENERATION_ENGINE: "openai"
IMAGE_GENERATION_MODEL: "gpt-image-2"
IMAGE_SIZE: "1024x1024"
ENABLE_IMAGE_PROMPT_GENERATION: "false"
ENABLE_IMAGE_EDIT: "true"
IMAGE_EDIT_ENGINE: "openai"
IMAGE_EDIT_MODEL: "gpt-image-2"
IMAGE_EDIT_SIZE: "1024x1024"
IMAGES_OPENAI_API_BASE_URL: "${OPENAI_API_BASE_URL}"
IMAGES_OPENAI_API_KEY: "${OPENAI_API_KEY}"
IMAGES_EDIT_OPENAI_API_BASE_URL: "${IMAGES_OPENAI_API_BASE_URL}"
IMAGES_EDIT_OPENAI_API_KEY: "${IMAGES_OPENAI_API_KEY}"
```

For production, update `/opt/open-webui/docker-compose.yml`, recreate the container, and then verify in `Admin Panel > Settings > Images` that image generation is enabled, the engine is `Open AI`, and the model is `gpt-image-2`.

## Useful Server Checks

Health:

```sh
docker inspect -f '{{.State.Health.Status}} {{.Name}}' open-webui
```

Logs:

```sh
docker logs --tail 100 open-webui
```

Config name:

```sh
curl -s http://127.0.0.1/api/config
```

Open WebUI branding/link scan inside container:

```sh
docker exec open-webui sh -lc \
  "grep -RIl --exclude=*.map 'openwebui.com' /app/build /app/backend/open_webui/static 2>/dev/null | head"
```

Prompt environment check:

```sh
docker exec open-webui sh -lc 'python3 - <<'"'"'PY'"'"'
import os, json
data = json.loads(os.environ.get("DEFAULT_PROMPT_SUGGESTIONS", "[]"))
for item in data:
    print(item["title"])
PY'
```

## Operational Cautions

- Do not delete the Docker volume unless intentionally resetting all app data.
- Do not print API keys from the database or environment in logs or documentation.
- The server receives repeated SSH scans; hardening should be treated as production work.
- Recommended future hardening:
  - Restrict SSH by cloud security group.
  - Rotate the root password.
  - Use a non-root SSH user.
  - Add a domain and HTTPS.
  - Review public signup settings.

## Upgrade Notes

The deployment currently uses `ghcr.io/open-webui/open-webui:main`, which can change frequently. For production stability, pin to a specific version after validating that branding and prompts still work.

Upgrade flow:

```sh
cd /opt/open-webui
cp -f docker-compose.yml docker-compose.yml.bak.$(date +%Y%m%d%H%M%S)
docker compose pull
docker compose up -d --force-recreate --remove-orphans
docker inspect -f '{{.State.Health.Status}}' open-webui
```

After an upgrade:

- Check `/api/config` still reports `Musk WebAI`.
- Check homepage starters still show three entries.
- Check `/workspace/models` does not show the disabled community block.
- Check Open WebUI-related frontend links still route to `http://www.muskapis.com`.
