#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

USE_ADI_REPO=n
CONFIG_LIBAD9166_IIO_CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr \
				-DCMAKE_BUILD_TYPE=Release \
				-DCMAKE_COLOR_MAKEFILE=OFF \
				-DPYTHON_BINDINGS=ON \
				-DWITH_DOC=OFF \
				-Bbuild -H."
BRANCH_LIBAD9166_IIO=staging/libiio1-support

CONFIG_LIBAD9361_IIO_CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr \
				-DCMAKE_BUILD_TYPE=Release \
				-DCMAKE_COLOR_MAKEFILE=OFF \
				-DPYTHON_BINDINGS=ON \
				-DWITH_DOC=OFF \
				-Bbuild -H."
BRANCH_LIBAD9361_IIO=staging/libiio1-support

if [ "${CONFIG_LIBAD9361_IIO}" = y ]; then

	if [ "${USE_ADI_REPO}" = y ]; then
		chroot "${BUILD_DIR}" apt-get install --no-install-recommends -y libad9361 libad9361-dev python3-libad9361

	elif [ "${CONFIG_LIBIIO}" = y ]; then

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone libad9361
		git clone -b ${BRANCH_LIBAD9361_IIO} ${GITHUB_ANALOG_DEVICES}/libad9361-iio
	
		# Install libad9361
		cd libad9361-iio && cmake ${CONFIG_LIBAD9361_IIO_CMAKE_ARGS} && cd build && make -j $NUM_JOBS && make install
EOF

	else
		echo "Cannot install Libad9361. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "Libad9361 won't be installed because CONFIG_LIBAD9361 is set to 'n'."
fi


if [ "${CONFIG_LIBAD9166_IIO}" = y ]; then

	if [ "${USE_ADI_REPO}" = y ]; then
		chroot "${BUILD_DIR}" apt-get install --no-install-recommends -y libad9166 libad9166-dev python3-libad9166 libad9166-dbgsym

	elif [ "${CONFIG_LIBIIO}" = y ]; then

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Clone libad9166
		git clone -b ${BRANCH_LIBAD9166_IIO} ${GITHUB_ANALOG_DEVICES}/libad9166-iio
	
		# Install libad9166
		cd libad9166-iio && cmake ${CONFIG_LIBAD9166_IIO_CMAKE_ARGS} && cd build && make -j $NUM_JOBS && make install
EOF

	else
		echo "Cannot install Libad9166. Libiio is a dependency and was not set to be installed. Please see the config file for more informations."
	fi
else
	echo "Libad9166 won't be installed because CONFIG_LIBAD9166 is set to 'n'."
fi
