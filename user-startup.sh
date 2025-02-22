#!/bin/bash
#MISTER2JAMMA Version, aje_fr

LOCAL_VERSION_FILE="/media/fat/linux/mister2jamma.version"
#default version
MISTER2JAMMA_UBOOT_VERSION="MISTER2JAMMA_1.0"
MISTER2JAMMA_KERNEL_VERSION="MISTER2JAMMA_1.5e"

FILE_BASE_URL="https://github.com/ajefr/mister2jamma/releases/download/Release"

INTERNET_AVAILABLE=0
reboot_de10=0

nc -z 8.8.8.8 53  >/dev/null 2>&1
online=$?
if [ $online -eq 0 ]; then
    INTERNET_AVAILABLE=1
fi

if [ "$INTERNET_AVAILABLE" == "1" ]; then
	# curl -k -f https://github.com/ajefr/mister2jamma/blob/309bcb702c408a15fc984d5b1115baa18afce0c6/mister2jamma.version -o "$LOCAL_VERSION_FILE"
	wget -q "$FILE_BASE_URL/mister2jamma.version" -O "$LOCAL_VERSION_FILE" || rm -f "$LOCAL_VERSION_FILE"
fi

if [ -f "$LOCAL_VERSION_FILE" ]; then
	MISTER2JAMMA_UBOOT_VERSION=$(cat "$LOCAL_VERSION_FILE" | grep "^MISTER2JAMMA_UBOOT_VERSION" | cut -d'=' -f2 )
	MISTER2JAMMA_KERNEL_VERSION=$(cat "$LOCAL_VERSION_FILE" | grep "^MISTER2JAMMA_KERNEL_VERSION" | cut -d'=' -f2 )
else
	echo "Problem with version file"
fi

echo "Mister2jamma UBOOT version  = $MISTER2JAMMA_UBOOT_VERSION"
echo "Mister2jamma KERNEL version = $MISTER2JAMMA_KERNEL_VERSION"

sed -i 's/^direct_video=0/direct_video=1/g' /media/fat/MiSTer.ini

#update json file to avoid auto reboot
if [ -f "/media/fat/Scripts/.config/update_all/update_all.json.zip" ]; then
  cd /media/fat/Scripts/.config/update_all
  unzip update_all.json.zip
  cat <<< $(jq '.autoreboot = false' update_all.json) > update_all.json
  zip update_all.json.zip update_all.json
  rm -f update_all.json.zip
fi

URL="https://github.com"

MISTER2JAMMA_UBOOT_URL="$FILE_BASE_URL/uboot.img_${MISTER2JAMMA_UBOOT_VERSION}"
MISTER2JAMMA_UBOOT_DEST="/media/fat/linux/uboot.img_${MISTER2JAMMA_UBOOT_VERSION}"

MISTER2JAMMA_KERNEL_URL="$FILE_BASE_URL/zImage_dtb_${MISTER2JAMMA_KERNEL_VERSION}"
MISTER2JAMMA_KERNEL_DEST="/media/fat/linux/zImage_dtb_${MISTER2JAMMA_KERNEL_VERSION}"

echo "Searching for $MISTER2JAMMA_UBOOT_DEST"
if ! cmp -s "$MISTER2JAMMA_UBOOT_DEST" "/media/fat/linux/uboot.img" ; then
  echo "Different uboot, updating"
	if [ "$INTERNET_AVAILABLE" == "1" ]; then
		# curl -k -f "$MISTER2JAMMA_UBOOT_URL" -o $MISTER2JAMMA_UBOOT_DEST
		wget "$MISTER2JAMMA_UBOOT_URL" -O $MISTER2JAMMA_UBOOT_DEST  || rm -f $MISTER2JAMMA_UBOOT_DEST
	fi
	# if [ $? -eq 0 ]; then
	if [ -f "$MISTER2JAMMA_UBOOT_DEST" ]; then
		echo "Updating MISTER2JAMMA uboot"
		cp $MISTER2JAMMA_UBOOT_DEST /media/fat/linux/uboot.img
		cd /media/fat/linux/
		./updateboot
		cd -
		reboot_de10=1
	else
		echo "Cannot update MISTER2JAMMA uboot, network error"
	fi
else
	echo "MISTER2JAMMA uboot already ok"
fi

echo "Searching for $MISTER2JAMMA_KERNEL_DEST"
if ! cmp -s "$MISTER2JAMMA_KERNEL_DEST" "/media/fat/linux/zImage_dtb" ; then
  echo "Different zImage, updating"
	if [ "$INTERNET_AVAILABLE" == "1" ]; then
		# curl -k -f "$MISTER2JAMMA_KERNEL_URL" -o $MISTER2JAMMA_KERNEL_DEST
		wget "$MISTER2JAMMA_KERNEL_URL" -O $MISTER2JAMMA_KERNEL_DEST || rm -f $MISTER2JAMMA_KERNEL_DEST
	fi
	# if [ $? -eq 0 ]; then
	if [ -f "$MISTER2JAMMA_KERNEL_DEST" ]; then
		echo "Updating MISTER2JAMMA zImage"
		cp $MISTER2JAMMA_KERNEL_DEST /media/fat/linux/zImage_dtb
		cd -
		reboot_de10=1
	else
		echo "Cannot update MISTER2JAMMA kernel, network error"
	fi
else
	echo "MISTER2JAMMA kernel already ok"
fi

echo "MISTER2JAMMA Boot process Finished !"

if [ $reboot_de10 == 1 ]; then
 echo "Rebooting board"
 sudo reboot
fi

exit 0
