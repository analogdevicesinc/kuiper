#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_LIBM2K}" = y ]; then
	if [ "${CONFIG_LIBIIO}" = y ]; then
		install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone libm2k
		git clone -b ${BRANCH_LIBM2K} ${GITHUB_ANALOG_DEVICES}/libm2k
	
		# Install libm2k
		cd libm2k && cmake ${CONFIG_LIBM2K_CMAKE_ARGS} && cd build && make -j $NUM_JOBS && make install
EOF

	else
		echo "Cannot install Libm2k. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "Libm2k won't be installed because CONFIG_LIBM2K is set to 'n'."
fi
