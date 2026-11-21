#!/bin/bash
# Build the MiSTer2JAMMA kernel module for the official MiSTer kernel.
# Usage: tools/build_module.sh <release> <build_date> <branch> <driver_src_dir>
#   release    e.g. 6.18.38-MiSTer   (must equal `uname -r` on the MiSTer)
#   build_date ISO date of the official kernel build (picks the matching commit)
#   branch     Linux-Kernel_MiSTer branch, e.g. MiSTer-v6.18
set -euo pipefail
RELEASE="$1"; BUILD_DATE="$2"; BRANCH="$3"; DRIVER="$(realpath "$4")"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${RUNNER_TEMP:-/tmp}/mister-kernel"
export ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

rm -rf "$WORK"
git clone -q --depth 400 -b "$BRANCH" https://github.com/MiSTer-devel/Linux-Kernel_MiSTer "$WORK"
cd "$WORK"
COMMIT=$(git rev-list -1 --before="$BUILD_DATE" HEAD)
echo "Kernel commit for $RELEASE built $BUILD_DATE: $COMMIT"
git checkout -q "$COMMIT"

BASE="${RELEASE%%-*}"                  # 6.18.38
SUFFIX="${RELEASE#"$BASE"}"            # -MiSTer
make -s MiSTer_defconfig
./scripts/config --set-str LOCALVERSION "$SUFFIX"
make -s olddefconfig
make -s LOCALVERSION= -j"$(nproc)" modules_prepare
GOT=$(cat include/config/kernel.release)
if [ "$GOT" != "$RELEASE" ]; then
	echo "Kernel release mismatch: built $GOT, expected $RELEASE" >&2
	exit 1
fi

make -s -C "$DRIVER" KDIR="$WORK" clean >/dev/null 2>&1 || true
make -s -C "$DRIVER" KDIR="$WORK" 2>&1 | grep -v -E "Module.symvers|unresolved symbol|KBUILD_MODPOST_WARN|modpost: \".*\" \[" || true
test -f "$DRIVER/mister2jamma.ko"
strings "$DRIVER/mister2jamma.ko" | grep -q "vermagic=$RELEASE " || { echo "vermagic mismatch" >&2; exit 1; }
cp "$DRIVER/mister2jamma.ko" "$REPO/db/files/Scripts/.config/mister2jamma/mister2jamma-$RELEASE.ko"
echo "Built db/files/Scripts/.config/mister2jamma/mister2jamma-$RELEASE.ko"
