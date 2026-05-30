#!/bin/sh
set -eu

WEBAI_CONTAINER="${WEBAI_CONTAINER:-open-webui}"

docker inspect "$WEBAI_CONTAINER" >/dev/null

if [ -f /tmp/musk-webai-ui-patch.sh ]; then
  docker cp /tmp/musk-webai-ui-patch.sh "$WEBAI_CONTAINER:/app/backend/data/musk-webai-ui-patch.sh"
fi

if [ -f /tmp/musk-webai-ui-rollback.sh ]; then
  docker cp /tmp/musk-webai-ui-rollback.sh "$WEBAI_CONTAINER:/app/backend/data/musk-webai-ui-rollback.sh"
fi

docker exec "$WEBAI_CONTAINER" sh -lc '
  set -eu
  patch="/app/backend/data/brand-patch.sh"
  marker="# MUSK_WEBAI_UI_PATCH_BEGIN"
  if [ ! -f "$patch" ]; then
    echo "missing $patch" >&2
    exit 1
  fi
  if ! grep -q "$marker" "$patch"; then
    cat >> "$patch" <<'"'"'EOF'"'"'

# MUSK_WEBAI_UI_PATCH_BEGIN
if [ -f /app/backend/data/musk-webai-ui-patch.sh ]; then
  sh /app/backend/data/musk-webai-ui-patch.sh
fi
# MUSK_WEBAI_UI_PATCH_END
EOF
  fi
  grep -n "MUSK_WEBAI_UI_PATCH" "$patch"
  ls -l /app/backend/data/musk-webai-ui-patch.sh /app/backend/data/musk-webai-ui-rollback.sh
'

docker inspect -f '{{.State.Health.Status}}' "$WEBAI_CONTAINER"
