#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

# Variable that selects if the boot files should be installed from the ADI APT Package Repository or from other source
# For normal use this variable will be left on 'y'
USE_ADI_REPO_CARRIERS_BOOT=n

SERVER="https://swdownloads.analog.com"
XILINX_INTEL_SPATH="cse/boot_partition_files"
XILINX_INTEL_ARCHIVE_NAME="latest_boot_partition.tar.gz"
XILINX_INTEL_PROPERTIES="latest_boot.txt"
RELEASE_XILINX_INTEL_BOOT_FILES="2025_r1"

if [ "${USE_ADI_REPO_CARRIERS_BOOT}" == y ]; then
		
# Install packages from adi-repo
chroot "${BUILD_DIR}" << EOF
	# Install only boot files packages for the architectures that are enabled
	# Look through environment variables, find those starting with 'CONFIG_ARCH_' and set to '=y'
	# Remove the 'CONFIG_ARCH_' prefix and the '=y' suffix, leaving only the architecture name
	# Convert result to lowercase
	# For each architecture check if package exists
	# Install package
	# Or print and info message
	env | grep '^CONFIG_ARCH_.*=y' \
		| sed -E 's/^CONFIG_ARCH_(.*)=y/\L\1/' \
		| while read arch; do
		apt-cache show adi-\$arch-boot >/dev/null 2>&1 \
		&& apt install adi-\$arch-boot \
		|| echo "Package adi-\$arch-boot not found for $TARGET_ARCHITECTURE"
	done
EOF

elif [[ ! -z ${ARTIFACTORY_XILINX_INTEL} ]]; then
	wget -r -q --progress=bar:force:noscroll -nH --cut-dirs=6 -np -R "index.html*" "-l inf" ${ARTIFACTORY_XILINX_INTEL} -P "${BUILD_DIR}/boot"
else
	# Get Xilinx and Intel boot files
	wget --progress=bar:force:noscroll "$SERVER/$XILINX_INTEL_SPATH/$RELEASE_XILINX_INTEL_BOOT_FILES/$XILINX_INTEL_ARCHIVE_NAME"
	if [ $? -ne 0 ]; then
		echo -e "\nDownloading $SERVER/$XILINX_INTEL_SPATH/$RELEASE_XILINX_INTEL_BOOT_FILES/$XILINX_INTEL_ARCHIVE_NAME failed - Aborting."  1>&2
		exit 1
	fi
		
	# Get Xilinx Intel properties file corresponding to boot files
	wget --progress=bar:force:noscroll "$SERVER/$XILINX_INTEL_SPATH/$RELEASE_XILINX_INTEL_BOOT_FILES/$XILINX_INTEL_PROPERTIES"
	if [ $? -ne 0 ]; then
		echo -e "Downloading $SERVER/$XILINX_INTEL_SPATH/$RELEASE_XILINX_INTEL_BOOT_FILES/$XILINX_INTEL_PROPERTIES failed - Aborting."  1>&2
		exit 1
	fi
		
	# Compute the checksum for the downloaded archive
	checksum_latest_boot=$(md5sum $XILINX_INTEL_ARCHIVE_NAME | cut -d' ' -f1)
	
	# Extract the checksum of the archive from XILINX_INTEL_PROPERTIES file
	checksum_current_boot=$(sed -n 3p $XILINX_INTEL_PROPERTIES | cut -d' ' -f2)

	# Check if the archive was downloaded correctly and then extract files
	if [ $checksum_latest_boot = $checksum_current_boot ]; then
		tar xf $XILINX_INTEL_ARCHIVE_NAME -C "${BUILD_DIR}"/boot --no-same-owner
	else
		echo "Something went wrong while downloading the boot files - Aborting."
		exit 1
	fi

	rm $XILINX_INTEL_ARCHIVE_NAME
	rm $XILINX_INTEL_PROPERTIES
fi
