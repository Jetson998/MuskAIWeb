#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/opt/open-webui}"
SERVICE="${SERVICE:-open-webui}"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
STAMP="$(date +%Y%m%d%H%M%S)"

cd "$APP_DIR"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "missing $COMPOSE_FILE" >&2
  exit 1
fi

cp "$COMPOSE_FILE" "$COMPOSE_FILE.bak.websocket.$STAMP"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("docker-compose.yml")
text = path.read_text()
line = '      ENABLE_WEBSOCKET_SUPPORT: "${ENABLE_WEBSOCKET_SUPPORT:-false}"'

if "ENABLE_WEBSOCKET_SUPPORT:" in text:
    text = re.sub(
        r"(?m)^\s*ENABLE_WEBSOCKET_SUPPORT:\s*.*$",
        line,
        text,
    )
else:
    anchors = [
        r'(?m)^      ENABLE_PERSISTENT_CONFIG:.*$',
        r'(?m)^      RAG_EMBEDDING_MODEL_AUTO_UPDATE:.*$',
        r'(?m)^      HF_HUB_OFFLINE:.*$',
        r'(?m)^      OFFLINE_MODE:.*$',
    ]
    for anchor in anchors:
        match = re.search(anchor, text)
        if match:
            insert_at = match.end()
            text = text[:insert_at] + "\n" + line + text[insert_at:]
            break
    else:
        raise SystemExit("could not find a safe environment anchor")

path.write_text(text)
PY

echo "== changed lines =="
grep -n "ENABLE_WEBSOCKET_SUPPORT\\|ENABLE_PERSISTENT_CONFIG" "$COMPOSE_FILE"

echo "== compose config check =="
docker compose config >/tmp/open-webui-compose-check.yml
echo "compose_config_ok"

echo "== restart =="
docker compose up -d "$SERVICE"

echo "== health wait =="
for _ in $(seq 1 60); do
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$SERVICE" 2>/dev/null || true)"
  echo "health=$health"
  [ "$health" = "healthy" ] && break
  sleep 2
done

echo "== final inspect =="
docker inspect "$SERVICE" --format 'image={{.Config.Image}} restart={{.RestartCount}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} oom={{.State.OOMKilled}}'
