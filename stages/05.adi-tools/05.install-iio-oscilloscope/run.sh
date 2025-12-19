#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_IIO_OSCILLOSCOPE}" = y ]; then
	if [[ "${CONFIG_LIBIIO}" = y && "${CONFIG_LIBAD9361_IIO}" = y && "${CONFIG_LIBAD9166_IIO}" = y ]]; then
		install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Install gtkdatabox-1.0.0
		wget https://downloads.sourceforge.net/project/gtkdatabox/gtkdatabox-1/gtkdatabox-1.0.0.tar.gz
		tar xvf gtkdatabox-1.0.0.tar.gz
		cd gtkdatabox-1.0.0 && ./configure && make install && cd ..
		rm gtkdatabox-1.0.0.tar.gz

		echo "export LD_LIBRARY_PATH=\"/usr/local/lib\"" >> /etc/bash.bashrc

		# Clone iio-oscilloscope
		git clone -b ${BRANCH_IIO_OSCILLOSCOPE} ${GITHUB_ANALOG_DEVICES}/iio-oscilloscope.git
		
		# Install iio-oscilloscope
		cd iio-oscilloscope && cmake ${CONFIG_IIO_OSCILLOSCOPE_CMAKE_ARGS} && cd build && make -j $NUM_JOBS && make install
EOF
	else
		echo "Cannot install IIO Oscilloscope. Libiio, Libad9361 and Libad9166 are dependencies and one or more of \
them were not set to be installed. Please see the config file for more informations."
	fi
else
	echo "IIO Oscilloscope won't be installed because CONFIG_IIO_OSCILLOSCOPE is set to 'n'."
fi
