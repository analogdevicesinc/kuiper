#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

USE_ADI_REPO=y
BRANCH_IIO_FM_RADIO=main

if [ "${CONFIG_IIO_FM_RADIO}" = y ]; then

	if [ "${USE_ADI_REPO}" = y ]; then
		chroot "${BUILD_DIR}" apt-get install --no-install-recommends -y iio-fm-radio iio-fm-radio-dbgsym

	else
chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone iio-fm-radio
		git clone -b ${BRANCH_IIO_FM_RADIO} ${GITHUB_ANALOG_DEVICES}/iio-fm-radio.git
		
		# Install iio-fm-radio
		cd iio-fm-radio && make -j $NUM_JOBS && make install
EOF
	fi

else
	echo "IIO Fm Radio won't be installed because CONFIG_IIO_FM_RADIO is set to 'n'."
fi
