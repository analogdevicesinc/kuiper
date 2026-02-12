#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_PYADI}" = y ]; then
	if [ "${CONFIG_LIBIIO}" = y ]; then

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
