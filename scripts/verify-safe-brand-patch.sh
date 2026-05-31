#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/opt/open-webui}"
CONTAINER="${CONTAINER:-open-webui}"
TARGET="/app/backend/data/brand-patch.sh"

echo "== syntax =="
docker exec "$CONTAINER" sh -n "$TARGET"
echo "syntax_ok"

echo "== dry run =="
docker exec "$CONTAINER" sh "$TARGET"

echo "== counts after dry run =="
docker exec "$CONTAINER" sh -lc "
  printf 'style='
  grep -o 'id=\"musk-webai-ui-polish\"' /app/build/index.html | wc -l | tr -d ' '
  printf ' runtime='
  grep -o 'id=\"musk-webai-ui-runtime\"' /app/build/index.html | wc -l | tr -d ' '
  printf ' legacy='
  grep -Eo 'id=\"musk-webai-sidebar-polish\"|id=\"musk-webai-runtime-polish\"' /app/build/index.html | wc -l | tr -d ' '
  echo
"

echo "== restart =="
cd "$APP_DIR"
docker compose restart "$CONTAINER"

for _ in $(seq 1 75); do
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$CONTAINER" 2>/dev/null || true)"
  echo "health=$health"
  [ "$health" = "healthy" ] && break
  sleep 2
done

sleep 52

echo "== final config =="
docker exec "$CONTAINER" sh -lc "curl -sS --max-time 8 http://127.0.0.1:8080/api/config | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({\"enable_websocket\": d[\"features\"].get(\"enable_websocket\"), \"name\": d.get(\"name\"), \"version\": d.get(\"version\")}, ensure_ascii=False))'"

echo "== final version =="
docker exec "$CONTAINER" sh -lc 'cat /app/build/_app/version.json; echo'

echo "== final counts =="
docker exec "$CONTAINER" sh -lc "
  printf 'style='
  grep -o 'id=\"musk-webai-ui-polish\"' /app/build/index.html | wc -l | tr -d ' '
  printf ' runtime='
  grep -o 'id=\"musk-webai-ui-runtime\"' /app/build/index.html | wc -l | tr -d ' '
  printf ' legacy='
  grep -Eo 'id=\"musk-webai-sidebar-polish\"|id=\"musk-webai-runtime-polish\"' /app/build/index.html | wc -l | tr -d ' '
  echo
"

echo "== logs =="
docker logs --since 2m "$CONTAINER" 2>&1 \
  | grep -E 'webai-startup|safe_brand_patch|updated /app/build|brand patch failed|Syntax error' \
  | tail -n 100 || true
