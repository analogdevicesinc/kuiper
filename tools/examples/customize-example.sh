#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

############## GUIDELINES ##############

# - This script runs INSIDE 'chroot', against a pre-built image's rootfs
#   * it works as if Kuiper is running, with the usual chroot limitations
# - It runs as root - no 'sudo' needed
# - The current directory is '/' (root) of the Kuiper rootfs.
# - To change the boot partition, write under /boot
# - This script is removed after it runs; it will NOT be in the resulting image

############## EXAMPLES ##############

# Install a package
#   apt-get update
#   apt-get install -y --no-install-recommends htop

# Install without recommends to keep the image small:
#   apt-get install -y --no-install-recommends <package>

# Enable a service
#   systemctl enable <service>.service

# Edit a boot partition file:
#   echo "dtparam=spi=on" >> /boot/config.txt
