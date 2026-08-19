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

# pip inspect: lists installed packages as JSON, including who installed each one
# installer=="pip": keeps only pip-installed packages, skipping apt's python3-* (debian) ones
# name==version: pins the exact installed version of each package
# --no-binary :all: : downloads only sources, not precompiled wheels
# --no-deps: does not download dependencies
chroot "${BUILD_DIR}" << EOF
	/usr/bin/python3 -m pip inspect 2>/dev/null \
	| /usr/bin/python3 -c 'import sys,json;[print(p["metadata"]["name"]+"=="+p["metadata"]["version"]) for p in json.load(sys.stdin)["installed"] if p.get("installer")=="pip"]' \
	| while read -r p; do /usr/bin/python3 -m pip download "\$p" --no-binary :all: --no-deps -d pip-src/; done
EOF

	umount "${BUILD_DIR}/pip-src"
	rm -r "${BUILD_DIR}/pip-src"

else
	echo "Sources won't be exported because EXPORT_SOURCES is set to 'n'."
fi
