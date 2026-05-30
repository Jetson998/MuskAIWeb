#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/opt/open-webui}"
CONTAINER="${CONTAINER:-open-webui}"

echo "== compose command/env relevant =="
cd "$APP_DIR"
sed -n '1,42p' docker-compose.yml

echo "== brand-patch hook tail =="
docker exec "$CONTAINER" sh -lc "grep -n 'MUSK_WEBAI_UI_PATCH\\|musk-webai-ui-patch' /app/backend/data/brand-patch.sh || true; tail -n 80 /app/backend/data/brand-patch.sh"

echo "== build injection counts inside container =="
docker exec "$CONTAINER" sh -lc "
  printf 'style='
  grep -o 'id=\"musk-webai-ui-polish\"' /app/build/index.html | wc -l | tr -d ' '
  printf '\nruntime='
  grep -o 'id=\"musk-webai-ui-runtime\"' /app/build/index.html | wc -l | tr -d ' '
  printf '\nlegacy='
  grep -Eo 'id=\"musk-webai-sidebar-polish\"|id=\"musk-webai-runtime-polish\"' /app/build/index.html | wc -l | tr -d ' '
  printf '\n'
"
