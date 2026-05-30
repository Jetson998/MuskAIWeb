python3 - <<'PY'
from pathlib import Path

css = '''
<style id="musk-webai-sidebar-polish">
  #sidebar button[aria-label="Search"],
  #sidebar button[aria-label="搜索"],
  #sidebar a[aria-label="Search"],
  #sidebar a[aria-label="搜索"] {
    display: none !important;
  }
</style>
'''

for path in (Path('/app/build/app.html'), Path('/app/build/index.html')):
    if not path.exists():
        continue
    text = path.read_text(errors='ignore')
    if 'musk-webai-sidebar-polish' not in text:
        text = text.replace('</head>', css + '\n</head>')
        path.write_text(text)

for root in (Path('/app/build/_app/immutable/chunks'), Path('/app/build/_app/immutable/nodes')):
    if not root.exists():
        continue
    for path in root.glob('*.js'):
        if path.name.endswith('.map'):
            continue
        text = path.read_text(errors='ignore')
        updated = text.replace('AI 对话探索区', '对话创作')
        if updated != text:
            path.write_text(updated)
PY
