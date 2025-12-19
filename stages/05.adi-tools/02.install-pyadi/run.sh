#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_PYADI}" = y ]; then
	if [ "${CONFIG_LIBIIO}" = y ]; then
		install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone pyadi
		git clone -b ${BRANCH_PYADI} ${GITHUB_ANALOG_DEVICES}/pyadi-iio.git
	
		# Install pyadi
		# --break-system-packages is needed in Debian 12 Bookworm to install packages with apt and pip in the same environment
		cd pyadi-iio && yes | pip install . --break-system-packages
EOF

	else
		echo "Cannot install Pyadi. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "Pyadi won't be installed because CONFIG_PYADI is set to 'n'."
fi
