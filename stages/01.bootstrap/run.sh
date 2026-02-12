#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [[ "$(uname -m)" != "aarch64" && "$(uname -m)" != "arm*" ]]; then
	update-binfmts --enable qemu-arm
fi

mkdir "${BUILD_DIR}"
debootstrap --arch=${TARGET_ARCHITECTURE} \
			--components "main,non-free,non-free-firmware" \
			--include=ca-certificates \
			--keyring "/usr/share/keyrings/debian-archive-"${DEBIAN_VERSION}"-stable.gpg" "${DEBIAN_VERSION}" "${BUILD_DIR}"

if [[ "$(uname -m)" != "aarch64" && "$(uname -m)" != "arm*" ]]; then
	cp /usr/bin/qemu-arm-static "${BUILD_DIR}"/usr/bin
fi

# Add adi-repo.list to sources.list
install -m 644 "${BASH_SOURCE%%/run.sh}"/files/adi-repo.list "${BUILD_DIR}/etc/apt/sources.list.d/adi-repo.list"

# Add adi-repo.gpg key to use adi-repo.list
wget https://swdownloads.analog.com/cse/adi-repo/adi-repo-key.public
cat adi-repo-key.public | gpg --dearmor > "${BUILD_DIR}/etc/apt/trusted.gpg.d/adi-repo.gpg"
rm adi-repo-key.public

if [ "${CONFIG_RPI_BOOT_FILES}" = y ]; then
	# Add raspi.list to sources.list
	install -m 644 "${BASH_SOURCE%%/run.sh}"/files/raspi.list "${BUILD_DIR}/etc/apt/sources.list.d/raspi.list"

	# Add raspberrypi.gpg key to use raspi.list
	gpg --dearmor \
    < "${BASH_SOURCE%%/run.sh}"/files/raspberrypi-archive-keyring.pgp \
    > "${BUILD_DIR}/etc/apt/trusted.gpg.d/raspberrypi-archive-stable.gpg"

fi

chroot "${BUILD_DIR}" << EOF
	apt-get update
	apt-get dist-upgrade -y
EOF

mkdir "${BUILD_DIR}"/stages
cp -r /stages "${BUILD_DIR}"/
cp config "${BUILD_DIR}"/
