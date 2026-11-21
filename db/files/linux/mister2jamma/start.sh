#!/bin/sh
# Chargement du driver MiSTer2JAMMA au demarrage.
# A appeler depuis /media/fat/linux/user-startup.sh :
#   [ -f /media/fat/linux/mister2jamma/start.sh ] && sh /media/fat/linux/mister2jamma/start.sh
# Cherche le module dans le dossier du script, quel que soit son nom
DIR=$(cd "$(dirname "$0")" && pwd)
KO="$DIR/mister2jamma-$(uname -r).ko"
[ -f "$KO" ] || KO="$DIR/mister2jamma.ko"
if [ ! -f "$KO" ]; then
	echo "MiSTer2JAMMA: aucun module pour le noyau $(uname -r)"
	exit 0
fi
lsmod | grep -q '^mister2jamma ' && exit 0
insmod "$KO" || echo "MiSTer2JAMMA: chargement impossible (voir dmesg)"
