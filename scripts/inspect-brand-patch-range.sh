#!/bin/sh
set -eu

CONTAINER="${CONTAINER:-open-webui}"
START="${START:-260}"
END="${END:-360}"

docker exec "$CONTAINER" sh -lc "nl -ba /app/backend/data/brand-patch.sh | sed -n '${START},${END}p'"
