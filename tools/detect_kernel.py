#!/usr/bin/env python3
"""Find the Linux kernel shipped by the official MiSTer distribution.

Reads the official Distribution_MiSTer database, and if its Linux release is not
yet listed in db/kernels.json, downloads it and extracts from zImage_dtb:
  - the kernel release string (e.g. 6.18.38-MiSTer), which must match the module vermagic
  - the kernel build date, used to pick the matching Linux-Kernel_MiSTer commit
Results are written to $GITHUB_OUTPUT (or printed).
"""
import io, json, os, re, subprocess, sys, tempfile, urllib.request, zipfile
from datetime import datetime, timedelta, timezone

DIST_DB = "https://raw.githubusercontent.com/MiSTer-devel/Distribution_MiSTer/main/db.json.zip"
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KERNELS = os.path.join(REPO, "db", "kernels.json")
TZ = {"CST": 8, "UTC": 0, "GMT": 0, "CET": 1, "CEST": 2, "EST": -5, "EDT": -4, "PST": -8, "PDT": -7, "JST": 9}


def out(**kv):
    path = os.environ.get("GITHUB_OUTPUT")
    lines = "".join(f"{k}={v}\n" for k, v in kv.items())
    if path:
        with open(path, "a") as f:
            f.write(lines)
    print(lines, end="")


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "mister2jamma-ci"})
    with urllib.request.urlopen(req, timeout=600) as r:
        return r.read()


def kernel_info(zimage):
    """Decompress the kernel payload (LZ4/gzip/xz/zstd) and read release + build date."""
    candidates = [
        (b"\x02\x21\x4c\x18", ["lz4", "-dc"]),
        (b"\x1f\x8b\x08", ["gzip", "-dc"]),
        (b"\xfd7zXZ\x00", ["xz", "-dc"]),
        (b"\x28\xb5\x2f\xfd", ["zstd", "-dc"]),
    ]
    for magic, cmd in candidates:
        start = zimage.find(magic)
        while start >= 0:
            raw = subprocess.run(cmd, input=zimage[start:], capture_output=True).stdout
            ver = re.search(rb"Linux version (\S+)", raw)
            date = re.search(rb"#\d+ SMP(?: PREEMPT)? (\w{3} \w{3} +\d+ \d\d:\d\d:\d\d) (\w+) (\d{4})", raw)
            if ver and date:
                return ver.group(1).decode(), date
            start = zimage.find(magic, start + 1)
    sys.exit("Unable to find the kernel version in zImage_dtb")


def main():
    with zipfile.ZipFile(io.BytesIO(fetch(DIST_DB))) as z:
        db = json.loads(z.read(z.namelist()[0]))
    linux = db["linux"]
    version = linux["version"]
    known = json.load(open(KERNELS)) if os.path.exists(KERNELS) else {}

    if version in known:
        out(linux_version=version, release=known[version], new="false")
        return

    with tempfile.TemporaryDirectory() as tmp:
        archive = os.path.join(tmp, "linux.7z")
        with open(archive, "wb") as f:
            f.write(fetch(linux["url"]))
        subprocess.run(["7z", "e", "-y", f"-o{tmp}", archive, "files/linux/zImage_dtb"],
                       check=True, stdout=subprocess.DEVNULL)
        zimage = open(os.path.join(tmp, "zImage_dtb"), "rb").read()

    release, m = kernel_info(zimage)
    tzname = m.group(2).decode()
    built = datetime.strptime(f"{m.group(1).decode()} {m.group(3).decode()}", "%a %b %d %H:%M:%S %Y")
    built = built.replace(tzinfo=timezone(timedelta(hours=TZ.get(tzname, 0))))
    out(linux_version=version, release=release, new="true",
        build_date=built.isoformat(), branch="MiSTer-v" + ".".join(release.split(".")[:2]))


if __name__ == "__main__":
    main()
