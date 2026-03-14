#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

export SCOPY_RELEASE=v2.1.0
export SCOPY_ARCHIVE=Scopy-${SCOPY_RELEASE}-Linux-${TARGET_ARCHITECTURE}-AppImage.zip
export SCOPY_PATH=https://github.com/analogdevicesinc/scopy/releases/download/${SCOPY_RELEASE}/${SCOPY_ARCHIVE}
export SCOPY=Scopy-${SCOPY_RELEASE}-Linux-${TARGET_ARCHITECTURE}

if [ "${CONFIG_SCOPY}" = y ]; then
	if [ "${CONFIG_LIBIIO}" = y ]; then

chroot "${BUILD_DIR}" << EOF

			# Install Scopy 2
			wget -q ${SCOPY_PATH}
			unzip ${SCOPY_ARCHIVE} && rm ${SCOPY_ARCHIVE}
			chmod +x ${SCOPY}.AppImage
			mv ${SCOPY}.AppImage /usr/local/bin

			# Add desktop file and icon
			mkdir -p /usr/local/share/scopy/icons/
			mkdir -p /usr/local/share/applications/
			cp stages/05.adi-tools/10.install-scopy/files/scopy.desktop /usr/local/share/applications/
			cp stages/05.adi-tools/10.install-scopy/files/scopy.png     /usr/local/share/scopy/icons/scopy.png
			sed -i 's/<name>/${SCOPY}.AppImage/g' /usr/local/share/applications/scopy.desktop

			echo "alias scopy='/usr/local/bin/${SCOPY}.AppImage'" >> /etc/bash.bashrc
			echo "alias Scopy='/usr/local/bin/${SCOPY}.AppImage'" >> /etc/bash.bashrc
EOF

	else
		echo "Cannot install Scopy. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "Scopy won't be installed because CONFIG_SCOPY is set to 'n'."
fi
