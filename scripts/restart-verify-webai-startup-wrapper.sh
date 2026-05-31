#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/opt/open-webui}"
CONTAINER="${CONTAINER:-open-webui}"
WRAPPER_LOCAL="${WRAPPER_LOCAL:-/tmp/start-webai-with-patches.sh}"
WRAPPER_CONTAINER="/app/backend/data/start-webai-with-patches.sh"

if [ ! -f "$WRAPPER_LOCAL" ]; then
  echo "missing wrapper: $WRAPPER_LOCAL" >&2
  exit 1
fi

docker cp "$WRAPPER_LOCAL" "$CONTAINER:$WRAPPER_CONTAINER"
docker exec "$CONTAINER" chmod +x "$WRAPPER_CONTAINER"

cd "$APP_DIR"
docker compose restart "$CONTAINER"

for _ in $(seq 1 75); do
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$CONTAINER" 2>/dev/null || true)"
  echo "health=$health"
  [ "$health" = "healthy" ] && break
  sleep 2
done

sleep 52

echo "== inspect =="
docker inspect "$CONTAINER" --format 'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} oom={{.State.OOMKilled}}'

echo "== version =="
docker exec "$CONTAINER" sh -lc 'cat /app/build/_app/version.json; echo'

echo "== injection counts =="
docker exec "$CONTAINER" sh -lc "
  printf 'style='
  grep -o 'id=\"musk-webai-ui-polish\"' /app/build/index.html | wc -l | tr -d ' '
  printf ' runtime='
  grep -o 'id=\"musk-webai-ui-runtime\"' /app/build/index.html | wc -l | tr -d ' '
  printf ' legacy='
  grep -Eo 'id=\"musk-webai-sidebar-polish\"|id=\"musk-webai-runtime-polish\"' /app/build/index.html | wc -l | tr -d ' '
  echo
"

echo "== wrapper logs =="
docker logs --since 2m "$CONTAINER" 2>&1 \
  | grep -E 'webai-startup|brand patch failed|updated /app/build' \
  | tail -n 80 || true
