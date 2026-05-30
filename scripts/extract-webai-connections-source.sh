#!/bin/sh
set -eu

CONTAINER="${CONTAINER:-open-webui}"

docker exec "$CONTAINER" python3 - <<'PY'
import json
from pathlib import Path

targets = {
    'src/lib/utils/connections.ts',
    'src/lib/stores/index.ts',
    'src/routes/+layout.svelte',
}

printed = set()
for p in Path('/app/build/_app/immutable').rglob('*.js.map'):
    try:
        data = json.loads(p.read_text(errors='ignore'))
    except Exception:
        continue
    sources = data.get('sources') or []
    contents = data.get('sourcesContent') or []
    for src, content in zip(sources, contents):
        normalized = src.replace('../../../../../../', '')
        if normalized in targets and normalized not in printed:
            printed.add(normalized)
            print(f'== {normalized} from {p} ==')
            print(content[:10000])
            print()
    if printed == targets:
        break

missing = targets - printed
if missing:
    print('missing:', ', '.join(sorted(missing)))
PY
