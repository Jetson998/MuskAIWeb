#!/bin/sh
set -eu

SERVER_URL="${SERVER_URL:-http://152.32.172.162}"
PATCH_SCRIPT="${PATCH_SCRIPT:-patches/musk-webai-ui-patch.sh}"
TEST_DIR="${TEST_DIR:-$(mktemp -d /private/tmp/musk-webai-ui-test.XXXXXX)}"

if [ ! -f "$PATCH_SCRIPT" ]; then
  echo "Patch script not found: $PATCH_SCRIPT" >&2
  exit 1
fi

mkdir -p "$TEST_DIR/_app"
echo "[simulate] downloading $SERVER_URL to $TEST_DIR/index.html"
curl --max-time 20 -sS "$SERVER_URL" -o "$TEST_DIR/index.html"

echo "[simulate] running patch twice to verify idempotence"
MUSK_WEBAI_BUILD_DIR="$TEST_DIR" sh "$PATCH_SCRIPT" >/dev/null
MUSK_WEBAI_BUILD_DIR="$TEST_DIR" sh "$PATCH_SCRIPT" >/dev/null

style_count="$(grep -o 'id="musk-webai-ui-polish"' "$TEST_DIR/index.html" | wc -l | tr -d ' ')"
runtime_count="$(grep -o 'id="musk-webai-ui-runtime"' "$TEST_DIR/index.html" | wc -l | tr -d ' ')"
legacy_count="$(grep -Eo 'id="musk-webai-sidebar-polish"|id="musk-webai-runtime-polish"' "$TEST_DIR/index.html" | wc -l | tr -d ' ')"

echo "[simulate] style_count=$style_count"
echo "[simulate] runtime_count=$runtime_count"
echo "[simulate] legacy_count=$legacy_count"
echo "[simulate] output=$TEST_DIR/index.html"

if [ "$style_count" != "1" ] || [ "$runtime_count" != "1" ] || [ "$legacy_count" != "0" ]; then
  echo "[simulate] failed idempotence check" >&2
  exit 1
fi

echo "[simulate] passed"
