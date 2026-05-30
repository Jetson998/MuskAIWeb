#!/bin/sh
set -eu

WEBAI_HOST="${WEBAI_HOST:-152.32.172.162}"
WEBAI_USER="${WEBAI_USER:-root}"
WEBAI_CONTAINER="${WEBAI_CONTAINER:-open-webui}"
PERSIST_UI_PATCH="${PERSIST_UI_PATCH:-false}"
PATCH_LOCAL="${1:-patches/musk-webai-ui-patch.sh}"
REMOTE_PATCH="/tmp/musk-webai-ui-patch.sh"
STAMP="$(date +%Y%m%d%H%M%S)"
REMOTE="${WEBAI_USER}@${WEBAI_HOST}"

if [ ! -f "$PATCH_LOCAL" ]; then
  echo "Patch file not found: $PATCH_LOCAL" >&2
  exit 1
fi

echo "[deploy] copying $PATCH_LOCAL to $REMOTE:$REMOTE_PATCH"
scp "$PATCH_LOCAL" "$REMOTE:$REMOTE_PATCH"

echo "[deploy] applying patch in container $WEBAI_CONTAINER"
ssh "$REMOTE" \
  "WEBAI_CONTAINER='$WEBAI_CONTAINER' STAMP='$STAMP' PERSIST_UI_PATCH='$PERSIST_UI_PATCH' sh -s" <<'REMOTE_SH'
set -eu

docker inspect "$WEBAI_CONTAINER" >/dev/null
docker exec "$WEBAI_CONTAINER" sh -lc "cp -f /app/backend/data/brand-patch.sh /app/backend/data/brand-patch.sh.bak.$STAMP 2>/dev/null || true"
docker cp /tmp/musk-webai-ui-patch.sh "$WEBAI_CONTAINER:/tmp/musk-webai-ui-patch.sh"
docker cp /tmp/musk-webai-ui-patch.sh "$WEBAI_CONTAINER:/app/backend/data/musk-webai-ui-patch.sh"
docker exec "$WEBAI_CONTAINER" sh /tmp/musk-webai-ui-patch.sh

if [ "$PERSIST_UI_PATCH" = "true" ]; then
  docker exec "$WEBAI_CONTAINER" sh -lc '
    set -eu
    patch="/app/backend/data/brand-patch.sh"
    marker="# MUSK_WEBAI_UI_PATCH_BEGIN"
    if [ -f "$patch" ] && ! grep -q "$marker" "$patch"; then
      cat >> "$patch" <<'"'"'EOF'"'"'

# MUSK_WEBAI_UI_PATCH_BEGIN
if [ -f /app/backend/data/musk-webai-ui-patch.sh ]; then
  sh /app/backend/data/musk-webai-ui-patch.sh
fi
# MUSK_WEBAI_UI_PATCH_END
EOF
    fi
  '
fi

docker inspect -f '{{.State.Health.Status}}' "$WEBAI_CONTAINER"
REMOTE_SH

echo "[deploy] done"
