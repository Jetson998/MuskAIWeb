#!/bin/sh
set -eu

python3 - <<'PY'
from pathlib import Path
import json
import os
import re
import time

build = Path(os.environ.get('MUSK_WEBAI_BUILD_DIR', '/app/build'))
html_paths = [build / 'index.html', build / 'app.html']
version_path = build / '_app/version.json'

STYLE_IDS = (
    'musk-webai-ui-polish',
    'musk-webai-sidebar-polish',
)
SCRIPT_IDS = (
    'musk-webai-ui-runtime',
    'musk-webai-runtime-polish',
)


def strip_existing(html: str) -> str:
    for style_id in STYLE_IDS:
        html = re.sub(
            rf'<style id="{re.escape(style_id)}">.*?</style>\s*',
            '',
            html,
            flags=re.S,
        )
    for script_id in SCRIPT_IDS:
        html = re.sub(
            rf'<script id="{re.escape(script_id)}">.*?</script>\s*',
            '',
            html,
            flags=re.S,
        )
    return html


for html_path in html_paths:
    if not html_path.exists():
        continue
    original = html_path.read_text(errors='ignore')
    updated = strip_existing(original)
    if updated != original:
        html_path.write_text(updated)
        print(f'updated {html_path}')

if version_path.exists():
    version_path.write_text(json.dumps({'version': f'musk-webai-ui-rollback-{int(time.time())}'}))
    print(f'updated {version_path}')
PY
