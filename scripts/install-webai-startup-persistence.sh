#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/opt/open-webui}"
CONTAINER="${CONTAINER:-open-webui}"
WRAPPER_LOCAL="${WRAPPER_LOCAL:-/tmp/start-webai-with-patches.sh}"
WRAPPER_CONTAINER="/app/backend/data/start-webai-with-patches.sh"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
STAMP="$(date +%Y%m%d%H%M%S)"

if [ ! -f "$WRAPPER_LOCAL" ]; then
  echo "missing wrapper script: $WRAPPER_LOCAL" >&2
  exit 1
fi

docker inspect "$CONTAINER" >/dev/null

cd "$APP_DIR"
cp "$COMPOSE_FILE" "$COMPOSE_FILE.bak.startup-persistence.$STAMP"

docker cp "$WRAPPER_LOCAL" "$CONTAINER:$WRAPPER_CONTAINER"
docker exec "$CONTAINER" chmod +x "$WRAPPER_CONTAINER"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("docker-compose.yml")
text = path.read_text()
new_block = '    command: >-\n      sh /app/backend/data/start-webai-with-patches.sh\n'

if 'sh /app/backend/data/start-webai-with-patches.sh' in text:
    updated = text
else:
    specific = re.compile(
        r'(?m)^    command: >-\n'
        r'      sh -lc "sh /app/backend/data/brand-patch\.sh; bash start\.sh"\n'
    )
    updated, count = specific.subn(new_block, text, count=1)
    if count != 1:
        generic = re.compile(r'(?ms)^    command: >-\n(?:      .+\n)+(?=    ports:\n)')
        updated, count = generic.subn(new_block, text, count=1)
    if count != 1:
        raise SystemExit("could not safely replace compose command block")

path.write_text(updated)
PY

echo "== wrapper =="
docker exec "$CONTAINER" ls -l "$WRAPPER_CONTAINER"

echo "== compose command =="
sed -n '1,12p' "$COMPOSE_FILE"

echo "== compose config check =="
docker compose config >/tmp/open-webui-compose-check.yml
echo "compose_config_ok"
