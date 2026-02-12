#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

# Add udiskie service
install -m 644 "${BASH_SOURCE%%/run.sh}"/files/udiskie.service "${BUILD_DIR}/lib/systemd/system/"

chroot "${BUILD_DIR}" << EOF
	# Enable udiskie service to run automatically at every boot
	systemctl enable udiskie
	
	# Suppress log printing
	echo "kernel.printk = 3 4 1 3" > /etc/sysctl.d/99-local.conf

EOF
