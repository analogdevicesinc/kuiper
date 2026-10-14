#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

chroot "${BUILD_DIR}" << EOF
	# Add root autologin in the serial-getty service
	sed -i '/ExecStart=/s/$/ --autologin root/' /lib/systemd/system/serial-getty\@.service
	systemctl enable serial-getty@ttyPS0.service
	systemctl enable serial-getty@ttyS0.service
	systemctl enable serial-getty@ttyGS0.service
	systemctl enable serial-getty@ttyGS1.service

	# Add list of virtual terminals to permit autologin
	sed -i '1s/^/auth sufficient pam_listfile.so item=tty sense=allow file=\/etc\/securetty onerr=fail apply=root\n/' /etc/pam.d/login
	echo "ttyPS0" >> /etc/securetty
	echo "ttyS0" >> /etc/securetty
	echo "ttyGS0" >> /etc/securetty
	echo "ttyGS1" >> /etc/securetty

	# Add an ANSI reset code at the begining of /etc/issue to clear any text formatting from boot messages
	sed -i '1s|^|\\\e[0m|' /etc/issue

	# Configure serial-getty for ttyPS0
	mkdir -p /etc/systemd/system/serial-getty@ttyPS0.service.d
	printf '[Service]\nType=simple\n' \
	> /etc/systemd/system/serial-getty@ttyPS0.service.d/override.conf
EOF
