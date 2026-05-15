#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

USE_ADI_REPO=n
CONFIG_LIBIIO_CMAKE_ARGS="-DWITH_HWMON=ON \
			-DWITH_SERIAL_BACKEND=ON \
			-DWITH_MAN=ON \
			-DWITH_EXAMPLES=ON \
			-DPYTHON_BINDINGS=ON \
			-DCMAKE_BUILD_TYPE=Release \
			-DCMAKE_COLOR_MAKEFILE=OFF \
			-Bbuild -H."
BRANCH_LIBIIO=libiio-v0


if [ "${CONFIG_LIBIIO}" = y ]; then

	if [ "${USE_ADI_REPO}" = y ]; then
		chroot "${BUILD_DIR}" apt-get install --no-install-recommends -y libiio0 libiio-dev libiio-utils python3-libiio iiod

	else
		install_packages "${BASH_SOURCE%/run.sh}"

		# Add iiod service
		install -m 644 "${BASH_SOURCE%%/run.sh}"/files/iiod.service	"${BUILD_DIR}/lib/systemd/system/"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone libiio
		git clone -b ${BRANCH_LIBIIO} ${GITHUB_ANALOG_DEVICES}/libiio.git
	
		# Install libiio
		cd libiio && cmake ${CONFIG_LIBIIO_CMAKE_ARGS} && cd build && make -j $NUM_JOBS && make install
	
		# Enable iiod service to start at every boot
		systemctl enable iiod
EOF
	fi

else
	echo "Libiio won't be installed because CONFIG_LIBIIO is set to 'n'."
fi
