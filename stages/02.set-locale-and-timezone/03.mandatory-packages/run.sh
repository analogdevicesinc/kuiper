#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

install_packages "${BASH_SOURCE%/run.sh}"

chroot "${BUILD_DIR}" << EOF
	# Install xserver-xorg inside chroot
	# Use DEBIAN_FRONTEND=noninteractive to suppress interactive prompt from keyboard-configuration package and use the default answer
	DEBIAN_FRONTEND=noninteractive apt-get install -y xserver-xorg
EOF
