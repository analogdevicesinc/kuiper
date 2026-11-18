#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# The settings of the Microchip PolarFire SoC boards (CONFIG_ARCH_MPFS):
# - the root autologin on the Linux console, MMUART1 (ttyS1): ttyS0 is the
#   console of the HSS, and 03.system-tweaks/02.root-autologin enables the
#   other serial consoles;
# - the login console on the ACM serial port of the USB gadget (ttyGS0), which
#   03.system-tweaks/02.root-autologin enables, without the TTY reset of
#   systemd (files/serial-getty-ttyGS0-no-reset.conf): systemd resets the
#   terminal of a getty under a lock on /dev/console, and the reset of ttyGS0
#   blocks on the write while no USB host reads the port, with the lock held,
#   so the consoles reset after it (ttyS1) would never get their login prompt;
# - iiod over the USB gadget of adi-scripts with 2 endpoint pairs: the MUSB of
#   the PolarFire SoC has 4 IN and 4 OUT endpoints, and the ACM serial
#   function of the gadget takes 2 IN and 1 OUT, so the adi-scripts default
#   (-n 3) does not bind to the controller. One endpoint pair is for the
#   context, one for a buffer.
# - README_serial_iio.txt on the boot partition: how to serve IIO on the ACM
#   serial port instead.

if [ "${CONFIG_ARCH_MPFS}" = y ]; then

chroot "${BUILD_DIR}" << EOF
	systemctl enable serial-getty@ttyS1.service
	echo "ttyS1" >> /etc/securetty
EOF

	install -D -m 644 "${BASH_SOURCE%%/run.sh}"/files/serial-getty-ttyGS0-no-reset.conf \
		"${BUILD_DIR}/etc/systemd/system/serial-getty@ttyGS0.service.d/no-reset.conf"

	if [ -f "${BUILD_DIR}/etc/default/iiod" ]; then
		sed -i 's/^\(IIOD_EXTRA_FFS_OPTS="\)-n 3 /\1-n 2 /' "${BUILD_DIR}/etc/default/iiod"
		if ! grep -q '^IIOD_EXTRA_FFS_OPTS="-n 2 ' "${BUILD_DIR}/etc/default/iiod"; then
			echo "Cannot set iiod to 2 USB endpoint pairs in /etc/default/iiod - Aborting."
			exit 1
		fi
	fi

	install -m 644 "${BASH_SOURCE%%/run.sh}"/files/README_serial_iio.txt "${BUILD_DIR}/boot/"

else
	echo "PolarFire SoC board settings won't be applied because CONFIG_ARCH_MPFS is set to 'n'."
fi
