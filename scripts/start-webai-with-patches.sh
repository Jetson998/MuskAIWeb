#!/bin/sh
set -eu

LOG_PREFIX="[webai-startup]"
UI_PATCH="/app/backend/data/musk-webai-ui-patch.sh"

run_patch() {
  name="$1"
  script="$2"
  if [ ! -f "$script" ]; then
    echo "$LOG_PREFIX missing $name patch: $script" >&2
    return 0
  fi

  echo "$LOG_PREFIX applying $name patch"
  if ! sh "$script"; then
    echo "$LOG_PREFIX $name patch failed; continuing startup" >&2
  fi
}

(
  for delay in 0 3 8 20 45; do
    sleep "$delay"
    run_patch "ui" "$UI_PATCH"
  done
) &

exec bash start.sh
