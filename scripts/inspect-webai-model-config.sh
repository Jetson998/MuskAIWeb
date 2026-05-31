#!/bin/sh
set -eu

python3 - <<'PY'
import json
import sqlite3

path = "/app/backend/data/webui.db"
con = sqlite3.connect(path)
con.row_factory = sqlite3.Row
cur = con.cursor()

print("== config table ==")
cols = [row["name"] for row in cur.execute("pragma table_info(config)")]
print(json.dumps(cols, ensure_ascii=False))

for row in cur.execute("select * from config"):
    item = dict(row)
    safe = {}
    for key, value in item.items():
        lower = key.lower()
        if any(token in lower for token in ("key", "secret", "password", "token")):
            safe[key] = "<redacted>"
            continue
        text = value if isinstance(value, str) else json.dumps(value, ensure_ascii=False)
        safe[key] = text[:5000] + ("...<truncated>" if len(text) > 5000 else "")
    print(json.dumps(safe, ensure_ascii=False, sort_keys=True))

print("== selected app config keys from db json ==")
for row in cur.execute("select * from config"):
    for value in dict(row).values():
        if not isinstance(value, str):
            continue
        try:
            data = json.loads(value)
        except Exception:
            continue
        if not isinstance(data, dict):
            continue
        for key in (
            "OPENAI_API_CONFIGS",
            "OPENAI_API_BASE_URLS",
            "ENABLE_OPENAI_API",
            "MODEL_ORDER_LIST",
            "DEFAULT_MODELS",
            "DEFAULT_PINNED_MODELS",
            "BYPASS_MODEL_ACCESS_CONTROL",
        ):
            if key in data:
                val = data[key]
                if "KEY" in key or "TOKEN" in key:
                    val = "<redacted>"
                print(key, json.dumps(val, ensure_ascii=False))

print("== users ==")
if "user" in [row["name"] for row in cur.execute("select name from sqlite_master where type='table'")]:
    user_cols = [row["name"] for row in cur.execute("pragma table_info(user)")]
    select_cols = [c for c in ("id", "email", "name", "role") if c in user_cols]
    for row in cur.execute(f"select {','.join(select_cols)} from user"):
        print(json.dumps(dict(row), ensure_ascii=False, sort_keys=True))

print("== access grants for active models ==")
tables = [row["name"] for row in cur.execute("select name from sqlite_master where type='table'")]
if "access_grant" in tables:
    grant_cols = [row["name"] for row in cur.execute("pragma table_info(access_grant)")]
    print("cols", json.dumps(grant_cols, ensure_ascii=False))
    active_ids = [row["id"] for row in cur.execute("select id from model where is_active = 1")]
    placeholders = ",".join("?" for _ in active_ids)
    if active_ids:
        query = f"select * from access_grant where resource_type='model' and resource_id in ({placeholders})"
        for row in cur.execute(query, active_ids):
            print(json.dumps(dict(row), ensure_ascii=False, sort_keys=True))
PY
