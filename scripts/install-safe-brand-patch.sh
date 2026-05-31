#!/bin/sh
set -eu

CONTAINER="${CONTAINER:-open-webui}"
SAFE_PATCH_LOCAL="${SAFE_PATCH_LOCAL:-/tmp/brand-patch-safe.sh}"
TARGET="/app/backend/data/brand-patch.sh"
STAMP="$(date +%Y%m%d%H%M%S)"

if [ ! -f "$SAFE_PATCH_LOCAL" ]; then
  echo "missing safe patch: $SAFE_PATCH_LOCAL" >&2
  exit 1
fi

docker inspect "$CONTAINER" >/dev/null

docker exec "$CONTAINER" sh -lc "cp -f '$TARGET' '$TARGET.bak.safe.$STAMP' 2>/dev/null || true"
docker cp "$SAFE_PATCH_LOCAL" "$CONTAINER:$TARGET"
docker exec "$CONTAINER" chmod +x "$TARGET"
docker exec "$CONTAINER" sh -n "$TARGET"

echo "installed_safe_brand_patch=$TARGET"
echo "backup=$TARGET.bak.safe.$STAMP"
