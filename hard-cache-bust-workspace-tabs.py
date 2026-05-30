from pathlib import Path
import json
import re
import time

build = Path('/app/build')
nodes_dir = build / '_app/immutable/nodes'
entry_dir = build / '_app/immutable/entry'
stamp = str(int(time.time()))

node7 = next((p for p in nodes_dir.glob('7.*.js') if '.musk' not in p.name), None)
if node7 is None:
    raise SystemExit('node 7 not found')

text = node7.read_text(errors='ignore')
text = text.replace('()=>d().t("Models")', '()=>"自训练模型"')
text = text.replace('h(e,1,`min-w-fit p-1.5 order-last ${t??""} transition select-none`)', 'h(e,1,`min-w-fit p-1.5 ${t??""} transition select-none`);e.style.order="999"')
text = text.replace('h(e,1,`min-w-fit p-1.5 ${t??""} transition select-none`),I(a,p)},[()=>i().url.pathname.includes("/workspace/models")', 'h(e,1,`min-w-fit p-1.5 ${t??""} transition select-none`);e.style.order="999",I(a,p)},[()=>i().url.pathname.includes("/workspace/models")')
text = re.sub(r'\n//# sourceMappingURL=.*$', '', text)

node7_new = nodes_dir / f'7.musk{stamp}.js'
node7_new.write_text(text)

app_candidates = sorted(entry_dir.glob('app.*.js'), key=lambda p: p.stat().st_mtime, reverse=True)
app = app_candidates[0]
app_text = app.read_text(errors='ignore')
for existing in nodes_dir.glob('7.*.js'):
    app_text = app_text.replace(existing.name, node7_new.name)

app_new = entry_dir / f'app.musk-tabs{stamp}.js'
app_new.write_text(app_text)

for html_path in (build / 'index.html', build / 'app.html'):
    if not html_path.exists():
        continue
    html = html_path.read_text(errors='ignore')
    for existing in entry_dir.glob('app.*.js'):
        html = html.replace(existing.name, app_new.name)
    html_path.write_text(html)

version_path = build / '_app/version.json'
if version_path.exists():
    version_path.write_text(json.dumps({'version': f'musk-webai-tabs-{stamp}'}))

print('node7_new', node7_new.name)
print('app_new', app_new.name)
