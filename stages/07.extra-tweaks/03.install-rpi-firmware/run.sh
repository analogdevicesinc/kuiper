#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_RPI_BOOT_FILES}" = y ]; then
	# Uncomment raspi.list repository
	sed -i 's/deb /#deb /' "${BUILD_DIR}/etc/apt/sources.list"
	sed -i 's/#deb /deb /' "${BUILD_DIR}/etc/apt/sources.list.d/raspi.list"

	# Install bluetooth and wifi firmware for Raspberry PI from raspi.list
	# Wifi firmware package from raspi.list contains files for RPI Zero W and RPI 3
	# in addition to the package from Debian repository
chroot "${BUILD_DIR}" << EOF
	apt-get update
	apt-get install -y firmware-brcm80211 bluez-firmware --no-install-recommends
EOF

	# Comment raspi.list repository
	sed -i 's/deb /#deb /' "${BUILD_DIR}/etc/apt/sources.list.d/raspi.list"
	sed -i 's/#deb /deb /' "${BUILD_DIR}/etc/apt/sources.list"

	cat ${BUILD_DIR}/etc/apt/sources.list
	cat ${BUILD_DIR}/etc/apt/sources.list.d/raspi.list

# Install graphical bluetooth and wifi managers
chroot "${BUILD_DIR}" << EOF
	apt-get update
	apt-get install -y wpasupplicant wireless-tools blueman
EOF

# Remove unwanted packages
chroot "${BUILD_DIR}" << EOF
	apt-get purge -y ghostscript
	apt-get autoremove -y
EOF

else
	echo "RPI wifi and bluetooth firmware won't be installed because CONFIG_RPI_BOOT_FILES is set to 'n'."
fi
