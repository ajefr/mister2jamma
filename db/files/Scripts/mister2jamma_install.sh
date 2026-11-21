#!/bin/bash
# MiSTer2JAMMA: one-time setup, run it ONCE from the Scripts menu (or over SSH).
# Adds the driver to linux/user-startup.sh so it is loaded at every boot, then loads it.
US=/media/fat/linux/user-startup.sh
START=/media/fat/Scripts/.config/mister2jamma/start.sh
LINE="[ -f $START ] && sh $START"

if [ ! -f "$START" ]; then
	echo "Driver not found: run update_all (or downloader) first."
	exit 1
fi

new_startup() {
	if [ -f /media/fat/linux/_user-startup.sh ]; then
		cp /media/fat/linux/_user-startup.sh "$US"
	else
		printf '#!/bin/sh\n\necho "***" $1 "***"\n' > "$US"
	fi
}

# Old MiSTer2JAMMA user-startup.sh (installs the custom 5.15 kernel at boot): replace it
if [ -f "$US" ] && grep -q "MISTER2JAMMA Version, aje_fr" "$US"; then
	cp "$US" "$US.mister2jamma_old"
	echo "Old MiSTer2JAMMA user-startup.sh saved as $US.mister2jamma_old"
	new_startup
fi
[ -f "$US" ] || new_startup
sed -i 's/\r$//' "$US"	# Windows line endings
# Earlier manual installs used linux/mister2jamma/: point the line to the new place
sed -i "s#/media/fat/linux/mister2jamma/start.sh#$START#g" "$US"

if grep -qF "$START" "$US"; then
	echo "Start at boot: already configured."
else
	if grep -qE '^[[:space:]]*exit' "$US"; then
		# insert before the first "exit", otherwise the line would never run
		awk -v l="$LINE" '!done && /^[[:space:]]*exit/ {print "# MiSTer2JAMMA"; print l; done=1} {print}' "$US" > "$US.tmp" && mv "$US.tmp" "$US"
	else
		printf '\n# MiSTer2JAMMA\n%s\n' "$LINE" >> "$US"
	fi
	echo "Start at boot: added to $US"
fi

sh "$START"
if lsmod | grep -q '^mister2jamma '; then
	echo "MiSTer2JAMMA driver loaded."
else
	echo "Driver not loaded: see 'dmesg | grep -i mister2jamma'"
fi
