#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

# Create an uncommented deb-src line in sources.list and raspi.list
sed -i 's/deb .*/&\n&/g' /etc/apt/sources.list
sed -i '$ s/deb /deb-src /' /etc/apt/sources.list

sed -i 's/#deb-src /deb-src /' /etc/apt/sources.list.d/raspi.list

apt update
cd /deb-src
for package in $(dpkg -l | awk '/ii/ { print $2 }'); do
	apt-get --download-only source $package
done

# Archive with compression level 6 (on a scale from 1 to 9 representing the trade-off between compression ratio and speed)
zip -r -6 "deb-src.zip" *
find . -not -name "deb-src.zip" -delete

# Comment sources installation from sources.list
sed -i 's/deb-src /#deb-src /' /etc/apt/sources.list

# Comment sources installation from raspi.list
sed -i 's/deb-src /#deb-src /' /etc/apt/sources.list.d/raspi.list

apt update

