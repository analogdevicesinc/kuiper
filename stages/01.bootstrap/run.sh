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

# When DEBIAN_SNAPSHOT is set, pin the base to a reproducible snapshot from
# snapshot.debian.org instead of the live mirror
DEBOOTSTRAP_MIRROR=""
if [ -n "${DEBIAN_SNAPSHOT}" ]; then
	DEBOOTSTRAP_MIRROR="https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}/"
	echo "Installing from Debian snapshot ${DEBIAN_SNAPSHOT}"
fi

debootstrap --arch=${TARGET_ARCHITECTURE} \
			--components "main,non-free,non-free-firmware" \
			--include=ca-certificates,curl,gnupg,wget \
			--keyring "/usr/share/keyrings/debian-archive-"${DEBIAN_VERSION}"-stable.gpg" "${DEBIAN_VERSION}" "${BUILD_DIR}" ${DEBOOTSTRAP_MIRROR}

# Point the chroot's apt sources at the same snapshot and disable the
# Valid-Until check so dist-upgrade and later stages stay pinned too
if [ -n "${DEBIAN_SNAPSHOT}" ]; then
	sed -i -E "s|^(deb(-src)?) \S+|\1 ${DEBOOTSTRAP_MIRROR}|" \
		"${BUILD_DIR}/etc/apt/sources.list"
	echo 'Acquire::Check-Valid-Until "false";' > "${BUILD_DIR}/etc/apt/apt.conf.d/10no-check-valid-until"
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
