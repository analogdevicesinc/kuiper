#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

# Install packages
apt-get update
apt-get install -y v4l-utils qv4l2 python3-jinja2

apt-get install -y g++ meson ninja-build pkg-config libyaml-dev python3-yaml python3-ply python3-jinja2 openssl libdw-dev libunwind-dev libudev-dev \
                libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libpython3-dev pybind11-dev \
                libevent-dev libdrm-dev libtiff-dev qt6-base-dev libboost-dev libfmt-dev


# Install libcamera
cd /usr/local/share/
git clone https://github.com/raspberrypi/libcamera.git
cd libcamera
meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dgstreamer=enabled -Dtest=false -Dlc-compliance=disabled \
                -Dcam=disabled -Dqcam=disabled -Ddocumentation=disabled -Dpycamera=enabled
ninja -C build install

# Install pix-utils and pykms
apt-get install -y python3-pip
yes | pip3 install --break-system-packages pix-utils git+https://github.com/tomba/pykms.git git+https://github.com/tomba/pixutils.git

# Install pyv4l2
mkdir -p /home/analog/Workspace
cd /home/analog/Workspace
git clone https://github.com/tomba/pyv4l2.git
yes | pip3 install --break-system-packages git+https://github.com/tomba/pyv4l2.git

mkdir -p gen_gmsl_dts
cd gen_gmsl_dts
wget -q -O - "https://api.github.com/repos/analogdevicesinc/linux/contents/arch/arm/boot/dts/overlays/gen_gmsl_dts?ref=$BRANCH_RPI_BOOT_FILES" | \
  grep -o '"download_url": "[^"]*' | \
  cut -d '"' -f 4 | \
  wget -i -

chown -R analog:analog /home/analog/Workspace