#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

# Variable EXTRA_SCRIPT should contain the path to the extra script. 
# The script must be placed inside 'kuiper' directory and the path should be relative to that directory.
# Example: EXTRA_SCRIPT=stages/07.extra-tweaks/01.extra-scripts/examples/extra-script-example.sh and file 'extra-script-example.sh' is placed in stages/07.extra-tweaks/01.extra-scripts/examples directory.

if [ ! -z "${EXTRA_SCRIPT}" ]; then
	# Check if file exists
	if [ -f "${EXTRA_SCRIPT}" ]; then
	
	# Run script inside chroot
chroot "${BUILD_DIR}" << EOF
		bash "${EXTRA_SCRIPT}"
EOF
	else
		echo "File ${EXTRA_SCRIPT} does not exist. Extra script not run."
	fi
else
	echo "No extra script to be run."
fi
