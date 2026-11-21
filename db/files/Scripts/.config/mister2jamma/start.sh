#!/bin/sh
# MiSTer2JAMMA: loads the driver at boot.
# Called from /media/fat/linux/user-startup.sh with:
#   [ -f /media/fat/Scripts/.config/mister2jamma/start.sh ] && sh /media/fat/Scripts/.config/mister2jamma/start.sh
#
# 1. makes sure the MiSTer2JAMMA database is known by the downloader (drop-in file)
# 2. loads the module matching the running kernel
# 3. if there is no module for this kernel (fresh install, old MiSTer release, kernel just updated),
#    runs the downloader once in the background to update the MiSTer and fetch the module,
#    then loads it (the downloader reboots by itself when the Linux system was updated)

DIR=$(cd "$(dirname "$0")" && pwd)
FAT=/media/fat
DB_URL="https://raw.githubusercontent.com/ajefr/mister2jamma/main/db/db.json.zip"
DROPIN="$FAT/downloader_mister2jamma.ini"
LOG="$DIR/auto_update.log"

# 1. database configuration
if [ ! -f "$DROPIN" ] && ! grep -qi '^[[:space:]]*\[mister2jamma\]' "$FAT/downloader.ini" 2>/dev/null; then
	printf '[mister2jamma]\ndb_url = %s\n' "$DB_URL" > "$DROPIN"
fi

find_ko() {
	KO="$DIR/mister2jamma-$(uname -r).ko"
	[ -f "$KO" ] || KO="$DIR/mister2jamma.ko"
	[ -f "$KO" ]
}

load() {
	lsmod | grep -q '^mister2jamma ' && return 0
	insmod "$KO" || echo "MiSTer2JAMMA: cannot load $KO (see dmesg)"
}

# 2. normal case
if find_ko; then
	load
	exit 0
fi

# 3. no module for this kernel: automatic update in the background
echo "MiSTer2JAMMA: no module for kernel $(uname -r), starting an automatic update (log: $LOG)"
(
	echo "=== $(date) kernel $(uname -r)"
	n=0
	until nc -z -w 3 github.com 443 >/dev/null 2>&1 || nc -z 8.8.8.8 53 >/dev/null 2>&1; do
		n=$((n + 1))
		if [ $n -ge 60 ]; then
			echo "No network: connect an Ethernet cable (or set up WiFi) and reboot."
			exit 0
		fi
		sleep 2
	done
	if [ -f "$FAT/Scripts/downloader.sh" ]; then
		bash "$FAT/Scripts/downloader.sh"
	elif [ -f "$FAT/Scripts/update_all.sh" ]; then
		bash "$FAT/Scripts/update_all.sh"
	else
		echo "Neither Scripts/downloader.sh nor Scripts/update_all.sh found."
	fi
	# reached when the downloader did not reboot: load the module if it arrived
	if find_ko; then
		load
		echo "Module loaded."
	else
		echo "Still no module for kernel $(uname -r): it is built within 24 hours, it will be retried at next boot."
	fi
) > "$LOG" 2>&1 < /dev/null &
exit 0
