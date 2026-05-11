#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${INSTALL_RPI_PACKAGES}" = y ]; then
	
	# Copy application launcher and icon for sense_emu
	install -d 								"${BUILD_DIR}/usr/local/share/sense"
	install -m 644 "${BASH_SOURCE%%/run.sh}"/files/sense_emu_gui.svg 	"${BUILD_DIR}/usr/local/share/sense/"
	install -d 								"${BUILD_DIR}/usr/local/share/applications/"
	install -m 644 "${BASH_SOURCE%%/run.sh}"/files/sense_emu_gui.desktop 	"${BUILD_DIR}/usr/local/share/applications/"

	
chroot "${BUILD_DIR}" << EOF
	# Uncomment packages installation from raspi.list
	sed -i 's/#deb /deb /' /etc/apt/sources.list.d/raspi.list
	
	apt update

	# Install raspi-config
	apt install -y raspi-config rpi-eeprom
	
	# Install python RPI GPIO packages
	apt install -y python3 python-is-python3 python3-pip pigpio python3-pigpio raspi-gpio python3-rpi-lgpio
	
	# Install vcdbg (tool for debugging VideoCore)
	apt install -y vcdbg
		
	# Install sense-hat and sense-emu
	apt install -y sense-hat python3-sense-emu
	yes | pip install sense-emu --break-system-packages
		
	# Comment package installation from raspi.list
	sed -i 's/deb /#deb /' /etc/apt/sources.list.d/raspi.list
EOF

else
	echo "Raspberry Pi specific packages won't be installed because INSTALL_RPI_PACKAGES is set to 'n'."
fi
