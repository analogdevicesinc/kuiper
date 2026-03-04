#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

USE_PIP_REPO=y
BRANCH_PYADI=main

if [ "${CONFIG_PYADI}" = y ]; then

	if [ "${USE_PIP_REPO}" = y ]; then
		chroot "${BUILD_DIR}" apt install python3-numpy -y
		chroot "${BUILD_DIR}" pip3 install pyadi-iio --break-system-packages

	elif [ "${CONFIG_LIBIIO}" = y ]; then
		install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone pyadi
		git clone -b ${BRANCH_PYADI} ${GITHUB_ANALOG_DEVICES}/pyadi-iio.git
	
		# Install pyadi
		cd pyadi-iio && yes | pip install . --break-system-packages
EOF

	else
		echo "Cannot install Pyadi. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "Pyadi won't be installed because CONFIG_PYADI is set to 'n'."
fi
