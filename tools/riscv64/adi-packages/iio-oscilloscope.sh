# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# iio-oscilloscope: the iio-oscilloscope package of the ADI Kuiper repository
# repackages the ADI AppImage, which has no riscv64 build. This builds it from
# source with the old debian/ packaging of the repository (CMake, found by
# dh), under the name Kuiper installs (iio-oscilloscope, not iio-osc), with
# the build dependencies of the source build of the Kuiper stage
# 05.adi-tools/05.install-iio-oscilloscope and of CMakeLists.txt. Sourced by
# build-pkgs.sh in the build tree.

sed -i -e 's/^Source: iio-osc$/Source: iio-oscilloscope/' -e 's/^Package: iio-osc$/Package: iio-oscilloscope/' \
	-e 's/^Build-Depends: .*/Build-Depends: debhelper (>= 9), cmake, pkg-config, libiio-dev, libad9361-dev, libad9166-dev, libgtk-3-dev, libglib2.0-dev, libgtkdatabox-dev, libmatio-dev, libfftw3-dev, libxml2-dev, libcurl4-openssl-dev, libjansson-dev, libavahi-common-dev, libserialport-dev/' \
	debian/control
mv debian/iio-osc.install debian/iio-oscilloscope.install
# (the date of the changelog is the date of the files in the package)
sed -i -e "1s/.*/iio-oscilloscope (${version}-1) unstable; urgency=low/" \
	-e "s/^\( -- .*>  \).*/\1$(date -R)/" debian/changelog
grep -q '^Package: iio-oscilloscope$' debian/control && grep -q libgtkdatabox-dev debian/control
