#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_JESD_EYE_SCAN_GTK}" = y ]; then
	if [ "${CONFIG_LIBIIO}" = y ]; then
		install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone jesd-eye-scan-gtk
		git clone -b ${BRANCH_JESD_EYE_SCAN_GTK} ${GITHUB_ANALOG_DEVICES}/jesd-eye-scan-gtk.git
		
		# Install jesd-eye-scan-gtk
		cd jesd-eye-scan-gtk && cmake ${CONFIG_JESD_EYE_SCAN_GTK_CMAKE_ARGS} && cd build && make -j $NUM_JOBS && make install
EOF

	else
		echo "Cannot install JESD Eye Scan GTK. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "JESD Eye Scan GTK won't be installed because CONFIG_JESD_EYE_SCAN_GTK is set to 'n'."
fi
