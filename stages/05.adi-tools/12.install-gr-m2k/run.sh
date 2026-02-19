#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

USE_ADI_REPO=y
CONFIG_GRM2K_CMAKE_ARGS="-Bbuild -H."
BRANCH_GRM2K=main

# Temporary Fix: Modify FindGMP.cmake to avoid arm64 compilation issue
export FINDGMP_PATH="/usr/lib/aarch64-linux-gnu/cmake/gnuradio/FindGMP.cmake"

if [ "${CONFIG_GRM2K}" = y ]; then

	if [ "${USE_ADI_REPO}" = y ]; then
		chroot "${BUILD_DIR}" apt-get install --no-install-recommends -y gr-m2k gr-m2k-dev python3-gr-m2k

	elif [[ "${CONFIG_LIBIIO}" = y  && "${CONFIG_LIBM2K}" = y && "${CONFIG_GNURADIO}" = y ]]; then

chroot "${BUILD_DIR}" << EOF
		cd /usr/local/src

		# Temporary Fix: Modify FindGMP.cmake to avoid arm64 compilation issue
		if [ -f "${FINDGMP_PATH}" ]; then
			if grep -q "pkg_check_modules(PC_GMP" "$FINDGMP_PATH"; then
				echo "Problematic pkg_check_modules line found in $FINDGMP_PATH - applying fix"

				# Create backup
				cp "$FINDGMP_PATH" "${FINDGMP_PATH}.orig"

				# Remove problematic pkg_check_modules line
				sed -i '/pkg_check_modules(PC_GMP/d' "$FINDGMP_PATH"

				echo "FindGMP.cmake pkg_check_modules fix applied"
			else
				echo "pkg_check_modules line not found - no need for fix"
			fi
		else
			echo "FindGMP.cmake not found at $FINDGMP_PATH - continuing without fix"
		fi

		# Clone gr-m2k
		git clone -b ${BRANCH_GRM2K} ${GITHUB_ANALOG_DEVICES}/gr-m2k.git

		# Install gr-m2k
		cd gr-m2k && cmake ${CONFIG_GRM2K_CMAKE_ARGS} && cd build && make -j $NUM_JOBS && make install

		# Temporary Fix: Restore original FindGMP.cmake
		if [ -f "${FINDGMP_PATH}" ] && [ -f "${FINDGMP_PATH}.orig" ]; then
			mv "${FINDGMP_PATH}.orig" "$FINDGMP_PATH"
			echo "Restored original FindGMP.cmake"
		fi
EOF

	else
		echo "Cannot install Grm2k. Libiio, Libm2k and Gnuradio are dependencies and one or more of them were not set to be installed. \
Please see the config file for more informations."
	fi
else
	echo "Grm2k won't be installed because CONFIG_GRM2K is set to 'n'."
fi
