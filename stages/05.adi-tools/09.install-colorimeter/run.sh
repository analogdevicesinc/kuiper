#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_COLORIMETER}" = y ]; then
	if [ "${CONFIG_LIBIIO}" = y ]; then
		install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone colorimeter
		git clone -b ${BRANCH_COLORIMETER} ${GITHUB_ANALOG_DEVICES}/colorimeter
	
		# Install colorimeter
		cd colorimeter && make -j $NUM_JOBS && make install
		yes | pip install . --break-system-packages		
EOF

	else
		echo "Cannot install Pyadi. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "Colorimeter won't be installed because CONFIG_COLORIMETER is set to 'n'."
fi
