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
			--include=ca-certificates,curl,gnupg,wget \
			--keyring "/usr/share/keyrings/debian-archive-"${DEBIAN_VERSION}"-stable.gpg" "${DEBIAN_VERSION}" "${BUILD_DIR}"

if [[ "$(uname -m)" != "aarch64" && "$(uname -m)" != "arm*" ]]; then
	cp /usr/bin/qemu-arm-static "${BUILD_DIR}"/usr/bin
fi

# Add adi-repo.list to sources.list
install -m 644 "${BASH_SOURCE%%/run.sh}"/files/prefer-adi "${BUILD_DIR}/etc/apt/preferences.d/prefer-adi"
install -m 644 "${BASH_SOURCE%%/run.sh}"/files/adi-libraries "${BUILD_DIR}/etc/apt/preferences.d/adi-libraries"

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

	# Add adi-kuiper package repository
	wget -qO- https://dl.cloudsmith.io/public/adi/kuiper/setup.deb.sh | bash
EOF

mkdir "${BUILD_DIR}"/stages
cp -r /stages "${BUILD_DIR}"/
cp config "${BUILD_DIR}"/
