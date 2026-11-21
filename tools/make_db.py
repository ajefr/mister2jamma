#!/usr/bin/env python3
"""Generate db/db.json.zip (MiSTer Downloader database format v1) from db/files/.

Usage: python3 tools/make_db.py [base_files_url]
Every path under db/files/ is the final path under /media/fat on the MiSTer.
"""
import hashlib, json, os, sys, time, zipfile

DB_ID = "mister2jamma"
DEFAULT_BASE = "https://raw.githubusercontent.com/ajefr/mister2jamma/main/db/files/"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.join(REPO, "db", "files")
OUT = os.path.join(REPO, "db", "db.json.zip")


def main():
    base = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_BASE
    if not base.endswith("/"):
        base += "/"
    files, folders = {}, {}
    for dirpath, _, names in os.walk(ROOT):
        for name in sorted(names):
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, ROOT).replace(os.sep, "/")
            with open(full, "rb") as f:
                data = f.read()
            files[rel] = {"hash": hashlib.md5(data).hexdigest(), "size": len(data)}
            parts = rel.split("/")[:-1]
            for i in range(1, len(parts) + 1):
                folders["/".join(parts[:i])] = {}
    db = {
        "v": 1,
        "db_id": DB_ID,
        "timestamp": int(time.time()),
        "base_files_url": base,
        "files": dict(sorted(files.items())),
        "folders": dict(sorted(folders.items())),
    }
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("db.json", json.dumps(db, indent=2))
    print(json.dumps(db, indent=2))


if __name__ == "__main__":
    main()
