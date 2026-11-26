#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Alisa-Dariana Roman <alisa.roman@analog.com>

echo "RPi 5 Workstation Setup"

WORKDIR="/home/analog/datax-workshop"

mkdir $WORKDIR

echo "Installing Kuiper Imager"

apt install stages/07.extra-tweaks/01.extra-scripts/examples-rpi5/kuiper-imager_2.0.0_arm64.deb

echo "Preparing 32-bit Kuiper image to be customized for CoraZ7s"

wget -O $WORKDIR/image.zip https://packages.analog.com/public/raw/files/kuiper_basic_32_image_2026.1.0.zip

unzip $WORKDIR/image.zip -d $WORKDIR

mv $WORKDIR/image_2026-09-21-ADI-Kuiper-Linux-armhf.img $WORKDIR/image_kuiper_32_basic_2026.1.0.img
