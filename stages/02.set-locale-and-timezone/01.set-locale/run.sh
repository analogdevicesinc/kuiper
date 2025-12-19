#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

install_packages "${BASH_SOURCE%/run.sh}"

# Set the default system locale to American English with UTF-8 character set
chroot "${BUILD_DIR}" << EOF	
	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
	echo "LANGUAGE=en_US.UTF-8" >> /etc/default/locale
	echo "LANG=en_US.UTF-8" >> /etc/default/locale
	echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
	locale-gen
EOF
