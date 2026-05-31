#!/bin/sh
set -eu

python3 - <<'PY'
from pathlib import Path
import re

build = Path("/app/build")
static_roots = [
    build,
    Path("/app/backend/open_webui/static"),
]
suffixes = {
    ".html",
    ".json",
    ".webmanifest",
    ".js",
    ".css",
    ".xml",
    ".txt",
}

url_patterns = [
    re.compile(r"https?://(?:www\.)?openwebui\.com[^\s\"'<>)`]*", re.I),
    re.compile(r"https?://docs\.openwebui\.com[^\s\"'<>)`]*", re.I),
    re.compile(r"https?://api\.openwebui\.com[^\s\"'<>)`]*", re.I),
    re.compile(r"https?://licenses\.api\.openwebui\.com[^\s\"'<>)`]*", re.I),
    re.compile(r"https?://github\.com/open-webui/open-webui[^\s\"'<>)`]*", re.I),
]

text_replacements = (
    ("Open WebUI", "Musk WebAI"),
    ("OpenWebUI", "MuskWebAI"),
    ("OPEN WEBUI", "MUSK WEBAI"),
)

changed = 0
for root in static_roots:
    if not root.exists():
        continue
    for path in root.rglob("*"):
        if not path.is_file() or path.suffix not in suffixes or path.suffix == ".map":
            continue
        try:
            data = path.read_text(errors="ignore")
        except Exception:
            continue

        updated = data
        for pattern in url_patterns:
            updated = pattern.sub("http://www.muskapis.com", updated)
        for old, new in text_replacements:
            updated = updated.replace(old, new)

        if updated != data:
            path.write_text(updated)
            changed += 1

print(f"safe_brand_patch_changed={changed}")
PY

if [ -f /app/backend/data/musk-webai-ui-patch.sh ]; then
  sh /app/backend/data/musk-webai-ui-patch.sh
fi
