#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${EXPORT_SOURCES}" = y ]; then

	mkdir -p kuiper-volume/sources/debootstrap
	mkdir -p kuiper-volume/sources/deb-src
	mkdir -p kuiper-volume/sources/pip-src
	

    	######################## Debootstrap package source ########################

	sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources
	apt update

	cd kuiper-volume/sources/debootstrap/

	# Download debootstrap sources
	apt-get --download-only source debootstrap
	
	cd /
	
	######################## Debian packages sources ########################
	
	mkdir "${BUILD_DIR}/deb-src"
	mount --bind /kuiper-volume/sources/deb-src "${BUILD_DIR}/deb-src"
	
chroot "${BUILD_DIR}" << EOF
	bash stages/08.export-stage/02.export-sources/01.deb-src-chroot/run-chroot.sh
EOF
	umount "${BUILD_DIR}/deb-src"
	rm -r "${BUILD_DIR}/deb-src"
	

	######################## Pip packages sources ########################

	mkdir "${BUILD_DIR}/pip-src"
	mount --bind /kuiper-volume/sources/pip-src "${BUILD_DIR}/pip-src"

# --format=freeze: install only one version of the package
# --no-binary :all: : downloads only sources, not precompiled weels
# --no-deps: does not download dependencies
# --no-build-isolation: avoid virtual environments
# || true: ensures that the script continues running even if the pip command is not installed, a package has missing or broken dependencies, or if the required wheels cannot be found
chroot "${BUILD_DIR}" << EOF
	pip list --format=freeze | xargs -I {} /usr/bin/python3 -m pip download {} --no-binary :all: --no-deps --no-build-isolation -d /pip-src/ || true
EOF

	umount "${BUILD_DIR}/pip-src"
	rm -r "${BUILD_DIR}/pip-src"

else
	echo "Sources won't be exported because EXPORT_SOURCES is set to 'n'."
fi
