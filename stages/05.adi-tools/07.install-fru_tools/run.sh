#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

USE_ADI_REPO=y
BRANCH_FRU_TOOLS=main

if [ "${CONFIG_FRU_TOOLS}" = y ]; then

	if [ "${USE_ADI_REPO}" = y ]; then
		chroot "${BUILD_DIR}" apt-get install --no-install-recommends -y fru-tools fru-tools-dbgsym

	else
		install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone fru_tools
		git clone -b ${BRANCH_FRU_TOOLS} ${GITHUB_ANALOG_DEVICES}/fru_tools.git
	
		# Install fru_tools
		cd fru_tools && make -j $NUM_JOBS && make install
EOF
	fi

else
	echo "Fru tools won't be installed because CONFIG_FRU_TOOLS is set to 'n'."
fi
