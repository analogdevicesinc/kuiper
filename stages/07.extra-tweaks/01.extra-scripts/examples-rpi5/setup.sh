#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

############## GUIDELINES ##############

# - This script is run inside 'chroot'. 
# 	* it works as if Kuiper is running on a system with a few limitations
# 	* check 'chroot' documentation for more informations
# - This script is run as root, there is no need to use 'sudo' command.
# - Current directory is '/' (root) of the Kuiper rootfs.
# - If a file needs to be copied, it should be placed inside 'kuiper'.
# - If a variable from the configuration file is needed, source the config file to access its value.
# - At this stage the Kuiper image is not yet partitioned. In order to modify what will be in the boot partition access /boot folder.
# - This script will not be in the resulted image. If this is necessary it should be copied manually.

echo "RPi 5 Workstation Setup"

WORKDIR="/home/analog/datax-workshop"

mkdir $WORKDIR

echo "Installing Kuiper Imager"

apt install stages/07.extra-tweaks/01.extra-scripts/examples-rpi5/kuiper-imager_2.0.0_arm64.deb

echo "Preparing 32-bit Kuiper image to be customized for CoraZ7s"

wget -O $WORKDIR/image.zip https://packages.analog.com/public/raw/files/kuiper_basic_32_image_2026.1.0.zip

unzip $WORKDIR/image.zip -d $WORKDIR

mv $WORKDIR/image_2026-09-21-ADI-Kuiper-Linux-armhf.img $WORKDIR/image_kuiper_32_basic_2026.1.0.img
