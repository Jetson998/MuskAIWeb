#!/bin/sh
set -eu

CONTAINER="${CONTAINER:-open-webui}"

echo "== api config =="
docker exec "$CONTAINER" sh -lc "curl -sS --max-time 8 http://127.0.0.1:8080/api/config | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({\"enable_websocket\": d[\"features\"].get(\"enable_websocket\"), \"version\": d.get(\"version\"), \"name\": d.get(\"name\")}, ensure_ascii=False))'"

echo "== polling probe internal =="
docker exec "$CONTAINER" sh -lc "curl -isS --max-time 8 'http://127.0.0.1:8080/ws/socket.io/?EIO=4&transport=polling&t=verify' | sed -n '1,18p'"

echo "== websocket probe internal =="
docker exec "$CONTAINER" sh -lc "curl -isS --max-time 5 --http1.1 -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' 'http://127.0.0.1:8080/ws/socket.io/?EIO=4&transport=websocket' | sed -n '1,16p' || true"

echo "== recent socket logs =="
docker logs --since 5m "$CONTAINER" 2>&1 \
  | grep -Ei 'socket|websocket|polling|Invalid transport|error|exception|traceback|disconnect|reconnect' \
  | tail -n 80 || true
