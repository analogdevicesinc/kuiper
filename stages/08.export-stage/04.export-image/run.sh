#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

EXPORT_ROOTFS_DIR="export_rootfs_dir"

BOOTLOADER_SIZE="$((8 * 1024 * 1024))"
BOOT_SIZE="$((2048 * 1024 * 1024))"
ROOT_SIZE=$(du --apparent-size -s "${BUILD_DIR}" --exclude var/cache/apt/archives --exclude boot --block-size=1 | cut -f 1)
ALIGN="$((4 * 1024 * 1024))"
ROOT_MARGIN="$(echo "(${ROOT_SIZE} * 0.2 + 200 * 1024 * 1024) / 1" | bc)"

BOOTLOADER_PART_START=$((ALIGN))
BOOTLOADER_PART_SIZE=$(((BOOTLOADER_SIZE + ALIGN - 1) / ALIGN * ALIGN))

BOOT_PART_START=$((BOOTLOADER_PART_START + BOOTLOADER_PART_SIZE))
BOOT_PART_SIZE=$(((BOOT_SIZE + ALIGN - 1) / ALIGN * ALIGN))

ROOT_PART_START=$((BOOT_PART_START + BOOT_PART_SIZE))
ROOT_PART_SIZE=$(((ROOT_SIZE + ROOT_MARGIN + ALIGN  - 1) / ALIGN * ALIGN))

IMG_SIZE=$((BOOT_PART_START + BOOT_PART_SIZE + ROOT_PART_SIZE + BOOTLOADER_PART_SIZE))
truncate -s "${IMG_SIZE}" "${IMG_FILE}"

parted --script "${IMG_FILE}" mklabel msdos
parted --script "${IMG_FILE}" unit B mkpart primary fat32 "${BOOT_PART_START}" "$((BOOT_PART_START + BOOT_PART_SIZE - 1))"
parted --script "${IMG_FILE}" unit B mkpart primary ext4 "${ROOT_PART_START}" "$((ROOT_PART_START + ROOT_PART_SIZE - 1))"
parted --script "${IMG_FILE}" unit B mkpart primary ext4 "${BOOTLOADER_PART_START}" "$((BOOTLOADER_PART_START + BOOTLOADER_PART_SIZE - 1))"

# Change the format of the third partition in the image using fdisk. The sed command is used to format the inputs provided to fdisk.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${IMG_FILE}
	t	#change partition type
	3	#partition number
	a2	#partition format
	w	#write partition table
	q	#quit
EOF

PARTED_OUT=$(parted -sm "${IMG_FILE}" unit b print)
BOOT_OFFSET=$(echo "${PARTED_OUT}" | grep -e '^1:' | cut -d':' -f 2 | tr -d B)
BOOT_LENGTH=$(echo "${PARTED_OUT}" | grep -e '^1:' | cut -d':' -f 4 | tr -d B)

ROOT_OFFSET=$(echo "${PARTED_OUT}" | grep -e '^2:' | cut -d':' -f 2 | tr -d B)
ROOT_LENGTH=$(echo "${PARTED_OUT}" | grep -e '^2:' | cut -d':' -f 4 | tr -d B)

BOOTLOADER_OFFSET=$(echo "${PARTED_OUT}" | grep -e '^3:' | cut -d':' -f 2 | tr -d B)
BOOTLOADER_LENGTH=$(echo "${PARTED_OUT}" | grep -e '^3:' | cut -d':' -f 4 | tr -d B)

cnt=0
until BOOT_DEV=$(losetup --show -f -o "${BOOT_OFFSET}" --sizelimit "${BOOT_LENGTH}" "${IMG_FILE}"); do
	if [ $cnt -lt 5 ]; then
		cnt=$((cnt + 1))
		echo "Error in losetup for BOOT_DEV.  Retrying..."
		sleep 5
	else
		echo "ERROR: losetup for BOOT_DEV failed; exiting"
		exit 1
	fi
done

cnt=0
until ROOT_DEV=$(losetup --show -f -o "${ROOT_OFFSET}" --sizelimit "${ROOT_LENGTH}" "${IMG_FILE}"); do
	if [ $cnt -lt 5 ]; then
		cnt=$((cnt + 1))
		echo "Error in losetup for ROOT_DEV.  Retrying..."
		sleep 5
	else
		echo "ERROR: losetup for ROOT_DEV failed; exiting"
		exit 1
	fi
done

cnt=0
until BOOTLOADER_DEV=$(losetup --show -f -o "${BOOTLOADER_OFFSET}" --sizelimit "${BOOTLOADER_LENGTH}" "${IMG_FILE}"); do
	if [ $cnt -lt 5 ]; then
		cnt=$((cnt + 1))
		echo "Error in losetup for BOOTLOADER_DEV.  Retrying..."
		sleep 5
	else
		echo "ERROR: losetup for BOOTLOADER_DEV failed; exiting"
		exit 1
	fi
done

echo "/boot: offset ${BOOT_OFFSET}, length ${BOOT_LENGTH}"
echo "/:     offset ${ROOT_OFFSET}, length ${ROOT_LENGTH}"
echo "blder: offset ${BOOTLOADER_OFFSET}, length ${BOOTLOADER_LENGTH}"

ROOT_FEATURES="^huge_file"
for FEATURE in metadata_csum 64bit; do
if grep -q "$FEATURE" /etc/mke2fs.conf; then
	ROOT_FEATURES="^$FEATURE,$ROOT_FEATURES"
fi
done

mkdosfs -n BOOT -F 32 -v "${BOOT_DEV}" > /dev/null
mkfs.ext4 -L rootfs -O "${ROOT_FEATURES}" "${ROOT_DEV}" > /dev/null

mkdir -p "${EXPORT_ROOTFS_DIR}"
mount -v "${ROOT_DEV}" "${EXPORT_ROOTFS_DIR}" -t ext4
mkdir -p "${EXPORT_ROOTFS_DIR}/boot"
mount -v "${BOOT_DEV}" "${EXPORT_ROOTFS_DIR}/boot" -t vfat

# Extract UUID of the image
IMGID="$(dd if="${IMG_FILE}" skip=440 bs=1 count=4 2>/dev/null | xxd -e | cut -f 2 -d' ')"

BOOT_PARTUUID="${IMGID}-01"
ROOT_PARTUUID="${IMGID}-02"

sed -i "s/BOOTDEV/PARTUUID=${BOOT_PARTUUID}/" "${BUILD_DIR}/etc/fstab"
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${BUILD_DIR}/etc/fstab"

if [ "${CONFIG_RPI_BOOT_FILES}" = y ]; then
	sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" "${BUILD_DIR}/boot/cmdline.txt"
fi

# Configure setup for a specific project and board
# Pass parameter BOOTLOADER_DEV because for Intel projects the bootloader partition needs to be written
install -m 755 "${BASH_SOURCE%/run.sh}"/files/configure-setup.sh "${BUILD_DIR}/usr/bin"

if [[ ! -z "${ADI_EVAL_BOARD}"  && ! -z "${CARRIER}" ]]; then

chroot "${BUILD_DIR}" << EOF
		bash configure-setup.sh ${ADI_EVAL_BOARD} ${CARRIER} ${BOOTLOADER_DEV}
EOF

else
	echo "Setup won't be configured because setup variables are null."
fi

rsync -aHAXx --exclude /var/cache/apt/archives --inplace --exclude /boot "${BUILD_DIR}/" "${EXPORT_ROOTFS_DIR}/"
rsync -rtx --inplace "${BUILD_DIR}/boot/" "${EXPORT_ROOTFS_DIR}/boot/"

sync

# Archive with compression level 6 (on a scale from 1 to 9 representing the trade-off between compression ratio and speed)
zip -v -6 "/kuiper-volume/image_"$(date +%Y-%m-%d)"-ADI-Kuiper-Linux-$TARGET_ARCHITECTURE.zip" "${IMG_FILE}"

echo "Kuiper archived image image_"$(date +%Y-%m-%d)"-ADI-Kuiper-Linux-$TARGET_ARCHITECTURE.zip can be found in /kuiper-volume directory"
