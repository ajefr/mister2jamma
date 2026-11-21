#!/usr/bin/env python3
"""Generate sdcard/mister2jamma_sdcard.zip: files to extract at the root of a MiSTer SD card.

Contents: linux/user-startup.sh (loads the driver at boot), the driver folder
Scripts/.config/mister2jamma/ (start.sh + every built module), Scripts/mister2jamma_install.sh
and downloader_mister2jamma.ini (drop-in file that adds the MiSTer2JAMMA database).
"""
import os, sys, zipfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = os.path.join(REPO, "db", "files")
OUT = os.path.join(REPO, "sdcard", "mister2jamma_sdcard.zip")
DB_URL = "https://raw.githubusercontent.com/ajefr/mister2jamma/main/db/db.json.zip"
FIXED_DATE = (2020, 1, 1, 0, 0, 0)  # reproducible zip: only changes when the content changes


def add(z, arcname, data, mode=0o644):
    info = zipfile.ZipInfo(arcname, FIXED_DATE)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = (0o100000 | mode) << 16
    z.writestr(info, data)


def main():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    entries = {}
    for dirpath, _, names in os.walk(FILES):
        for name in names:
            full = os.path.join(dirpath, name)
            entries[os.path.relpath(full, FILES).replace(os.sep, "/")] = open(full, "rb").read()
    entries["linux/user-startup.sh"] = open(os.path.join(REPO, "extras", "sdcard", "linux", "user-startup.sh"), "rb").read()
    entries["downloader_mister2jamma.ini"] = ("[mister2jamma]\ndb_url = %s\n" % DB_URL).encode()
    with zipfile.ZipFile(OUT, "w") as z:
        for arcname in sorted(entries):
            add(z, arcname, entries[arcname], 0o755 if arcname.endswith(".sh") else 0o644)
    for arcname in sorted(entries):
        print(arcname)


if __name__ == "__main__":
    sys.exit(main())
