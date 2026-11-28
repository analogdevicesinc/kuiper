#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.

if [ "${CONFIG_FIRMWARE}" = y ]; then
chroot "${BUILD_DIR}" << EOF
	apt-get install adi-firmware
EOF
else
	echo "Firmware won't be installed because CONFIG_FIRMWARE is set to 'n'."
fi
