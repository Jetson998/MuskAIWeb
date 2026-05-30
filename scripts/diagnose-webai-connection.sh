#!/bin/sh
set -eu

CONTAINER="${CONTAINER:-open-webui}"

echo "== container =="
docker inspect "$CONTAINER" --format 'image={{.Config.Image}} restart={{.RestartCount}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} oom={{.State.OOMKilled}} ports={{json .NetworkSettings.Ports}}'

echo "== env filtered =="
docker exec "$CONTAINER" sh -lc "env | sort | grep -E '^(ENABLE_|WEBUI_|OPEN_WEBUI_|GLOBAL_|PORT=|HOST=|UVICORN_|SCARF_|DOCKER_|WEBSOCKET_)' | grep -Ev '(KEY|SECRET|TOKEN|PASSWORD|PASS=)' || true"

echo "== api config =="
docker exec "$CONTAINER" sh -lc "curl -sS --max-time 5 http://127.0.0.1:8080/api/config | head -c 1600; echo"

echo "== socket env values =="
docker exec "$CONTAINER" sh -lc "python3 - <<'PY'
from open_webui import env
for name in [
    'ENABLE_WEBSOCKET_SUPPORT',
    'WEBSOCKET_MANAGER',
    'WEBSOCKET_SERVER_PING_INTERVAL',
    'WEBSOCKET_SERVER_PING_TIMEOUT',
    'WEBSOCKET_EVENT_CALLER_TIMEOUT',
    'WEBSOCKET_SERVER_LOGGING',
    'WEBSOCKET_SERVER_ENGINEIO_LOGGING',
    'GLOBAL_LOG_LEVEL',
]:
    print(f'{name}={getattr(env, name, None)!r}')
PY"

echo "== socket backend source =="
docker exec "$CONTAINER" sh -lc "sed -n '60,105p' /app/backend/open_webui/socket/main.py"

echo "== asgi middleware socket section =="
docker exec "$CONTAINER" sh -lc "sed -n '165,220p' /app/backend/open_webui/utils/asgi_middleware.py"

echo "== internal websocket handshake =="
docker exec "$CONTAINER" sh -lc "curl -isS --max-time 5 --http1.1 -H 'Connection: Upgrade' -H 'Upgrade: websocket' -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' 'http://127.0.0.1:8080/ws/socket.io/?EIO=4&transport=websocket' | sed -n '1,24p' || true"

echo "== internal polling probe =="
docker exec "$CONTAINER" sh -lc "curl -isS --max-time 5 'http://127.0.0.1:8080/ws/socket.io/?EIO=4&transport=polling&t=diagnose' | sed -n '1,24p' || true"

echo "== frontend socket snippets =="
docker exec "$CONTAINER" sh -lc "python3 - <<'PY'
from pathlib import Path
terms = ['/ws/socket.io', 'io(', 'transports', 'reconnection', 'pingTimeout', 'pingInterval']
printed = 0
for p in Path('/app/build/_app/immutable').rglob('*.js'):
    if '.map' in p.name or '/assets/' in str(p):
        continue
    try:
        s = p.read_text(errors='ignore')
    except Exception:
        continue
    hits = [t for t in terms if t in s]
    if not hits:
        continue
    print('FILE', p, 'HITS', ','.join(hits))
    for t in hits:
        i = s.find(t)
        snippet = s[max(0, i - 220):i + 420].replace('\\n', ' ')
        print(snippet[:760])
        print('---')
        printed += 1
        if printed >= 16:
            raise SystemExit
PY"

echo "== recent socket/error logs =="
docker logs --since 24h "$CONTAINER" 2>&1 \
  | grep -Ei 'websocket|socket|disconnect|reconnect|connection|error|exception|traceback|timeout|ping|pong|closed|close|orphaned|Invalid transport' \
  | tail -n 220 || true
