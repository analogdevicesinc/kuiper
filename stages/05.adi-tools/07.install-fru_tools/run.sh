#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_FRU_TOOLS}" = y ]; then
	install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
	cd /usr/local/src

	# Clone fru_tools
	git clone -b ${BRANCH_FRU_TOOLS} ${GITHUB_ANALOG_DEVICES}/fru_tools.git
	
	# Install fru_tools
	cd fru_tools && make -j $NUM_JOBS && make install
EOF

else
	echo "Fru tools won't be installed because CONFIG_FRU_TOOLS is set to 'n'."
fi
