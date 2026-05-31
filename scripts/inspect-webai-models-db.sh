#!/bin/sh
set -eu

python3 - <<'PY'
import json
import os
import sqlite3

path = "/app/backend/data/webui.db"
print("db_exists", os.path.exists(path), path)

con = sqlite3.connect(path)
con.row_factory = sqlite3.Row
cur = con.cursor()

tables = [row["name"] for row in cur.execute(
    "select name from sqlite_master where type='table' order by name"
)]
print("tables", json.dumps(tables, ensure_ascii=False))

for table in ("model", "models"):
    if table not in tables:
        print("missing_table", table)
        continue

    cols = [row["name"] for row in cur.execute(f"pragma table_info({table})")]
    print("table", table, json.dumps(cols, ensure_ascii=False))

    rows = cur.execute(f"select * from {table} limit 50").fetchall()
    for row in rows:
        payload = dict(row)
        for key, value in list(payload.items()):
            if isinstance(value, str) and len(value) > 600:
                payload[key] = value[:600] + "...<truncated>"
        print("row", json.dumps(payload, ensure_ascii=False, sort_keys=True))
PY
