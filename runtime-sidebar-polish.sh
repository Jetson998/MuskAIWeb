python3 - <<'PY'
from pathlib import Path
import json
import time

runtime = '''
<script id="musk-webai-runtime-polish">
  (() => {
    const polish = () => {
      const walker = document.createTreeWalker(document.body || document.documentElement, NodeFilter.SHOW_TEXT);
      const nodes = [];
      while (walker.nextNode()) nodes.push(walker.currentNode);
      for (const node of nodes) {
        if (node.nodeValue && node.nodeValue.includes('AI 对话探索区')) {
          node.nodeValue = node.nodeValue.replaceAll('AI 对话探索区', '对话创作');
        }
      }
      document
        .querySelectorAll('#sidebar button[aria-label="Search"], #sidebar button[aria-label="搜索"], #sidebar a[aria-label="Search"], #sidebar a[aria-label="搜索"]')
        .forEach((el) => {
          el.style.setProperty('display', 'none', 'important');
        });
    };
    polish();
    document.addEventListener('DOMContentLoaded', polish);
    new MutationObserver(polish).observe(document.documentElement, { childList: true, subtree: true, characterData: true });
  })();
</script>
'''

build = Path('/app/build')
for path in (build / 'index.html', build / 'app.html'):
    if not path.exists():
        continue
    text = path.read_text(errors='ignore')
    start = text.find('<script id="musk-webai-runtime-polish">')
    if start != -1:
        end = text.find('</script>', start)
        if end != -1:
            text = text[:start] + text[end + len('</script>'):]
    text = text.replace('</body>', runtime + '\n</body>')
    path.write_text(text)

version_path = build / '_app/version.json'
if version_path.exists():
    version_path.write_text(json.dumps({'version': f'musk-webai-runtime-{int(time.time())}'}))
PY
