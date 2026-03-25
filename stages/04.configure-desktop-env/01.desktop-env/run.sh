#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_DESKTOP}" = y ]; then

	install_packages "${BASH_SOURCE%/run.sh}"

	if [[ "${CONFIG_RPI_BOOT_FILES}" = y && "${TARGET_ARCHITECTURE}" = arm64 ]]; then

		# Use the vc4 card for the display on RPi5
		install -m 644 "${BASH_SOURCE%%/run.sh}"/files/99-vc4.conf "${BUILD_DIR}/etc/X11/xorg.conf.d"

	fi

chroot "${BUILD_DIR}" << EOF
	# Remove unwanted packages
	apt purge -y xiccd colord colord-data

	# Enable autologin for analog user
	sed -i "s/#autologin-user=/autologin-user=analog/g" /etc/lightdm/lightdm.conf
	sed -i "s/#autologin-user-timeout=0/autologin-user-timeout=0/g" /etc/lightdm/lightdm.conf
	sed -i "s/#logind-check-graphical=false/logind-check-graphical=true/g" /etc/lightdm/lightdm.conf
	
	# Create only one workspace
	sed -i "s/^workspace_count=.*$/workspace_count=1/g" /usr/share/xfwm4/defaults
	
	echo "export CHROMIUM_FLAGS=\"\$CHROMIUM_FLAGS --password-store=basic\"" >> /etc/chromium.d/default-flags
EOF

else
	echo "XFCE desktop environment won't be installed because CONFIG_DESKTOP is set to 'n'."
fi
