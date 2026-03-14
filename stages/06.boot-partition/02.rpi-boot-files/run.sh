#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

USE_ADI_REPO_RPI_BOOT=n

# Variables used for custom downloads from SWDownloads or Artifactory for testing purposes
SERVER="https://swdownloads.analog.com"
RPI_SPATH="cse/linux_rpi"
RPI_PROPERTIES="rpi_archives_properties.txt"
BRANCH_RPI_BOOT_FILES="rpi-6.12.y"

if [ "${TARGET_ARCHITECTURE}" = armhf ]; then
	RPI_MODULES_ARCHIVE_NAME="rpi_modules_32bit.tar.gz"
	RPI_ARCHIVE_NAME="rpi_latest_boot_32bit.tar.gz"

else
	RPI_MODULES_ARCHIVE_NAME="rpi_modules_64bit.tar.gz"
	RPI_ARCHIVE_NAME="rpi_latest_boot_64bit.tar.gz"
fi

if [ "${CONFIG_RPI_BOOT_FILES}" = y ]; then
	mkdir -p "${BUILD_DIR}"/lib/modules
	echo "Download Raspberry Pi boot files"

	# Check if RPI boot files should be downloaded from ADI repository, Artifactory or Software downloads
	if [ "${USE_ADI_REPO_RPI_BOOT}" == y ]; then

		# install package from adi-repo
chroot "${BUILD_DIR}" << EOF
		apt-get install adi-rpi-boot
EOF

	elif [[ ! -z ${ARTIFACTORY_RPI} ]]; then
		wget -r -q --progress=bar:force:noscroll -nH --cut-dirs=5 -np -R "index.html*" "-l inf" ${ARTIFACTORY_RPI} -P "${BUILD_DIR}/boot"
		tar -xf "${BUILD_DIR}/boot/${RPI_MODULES_ARCHIVE_NAME}" -C "${BUILD_DIR}/lib/modules" --no-same-owner
		rm -rf "${BUILD_DIR}/boot/${RPI_MODULES_ARCHIVE_NAME}"
	else
		# Get Raspberry Pi properties file corresponding to boot files
		wget --progress=bar:force:noscroll "$SERVER/$RPI_SPATH/$BRANCH_RPI_BOOT_FILES/$RPI_PROPERTIES"
		if [ $? -ne 0 ]; then
			echo -e "\nDownloading $SERVER/$RPI_SPATH/$BRANCH_RPI_BOOT_FILES/$RPI_PROPERTIES failed - Aborting."  1>&2
			exit 1
		fi

		# Get custom ADI Raspberry Pi boot files brcm*.dtb, kernel*.img and overlays
		wget --progress=bar:force:noscroll "$SERVER/$RPI_SPATH/$BRANCH_RPI_BOOT_FILES/$RPI_ARCHIVE_NAME"
		if [ $? -ne 0 ]; then
			echo -e "\nDownloading $SERVER/$RPI_SPATH/$BRANCH_RPI_BOOT_FILES/$RPI_ARCHIVE_NAME failed - Aborting."  1>&2
  			exit 1
		fi
		
		# Get Raspberry Pi modules
		wget --progress=bar:force:noscroll "$SERVER/$RPI_SPATH/$BRANCH_RPI_BOOT_FILES/$RPI_MODULES_ARCHIVE_NAME"
		if [ $? -ne 0 ]; then
			echo -e "\nDownloading $SERVER/$RPI_SPATH/$BRANCH_RPI_BOOT_FILES/$RPI_MODULES_ARCHIVE_NAME failed - Aborting."  1>&2
  			exit 1
		fi

		# Extract checksum from modules and boot files
		if [ "${TARGET_ARCHITECTURE}" = armhf ]; then
			checksum_properties_modules=$(grep '^checksum_modules_32bit=' $RPI_PROPERTIES | cut -d'=' -f2)
			checksum_properties_boot_files=$(grep '^checksum_boot_files_32bit=' "$RPI_PROPERTIES" | cut -d'=' -f2)
		else
			checksum_properties_modules=$(grep '^checksum_modules_64bit=' $RPI_PROPERTIES | cut -d'=' -f2)
			checksum_properties_boot_files=$(grep '^checksum_boot_files_64bit=' "$RPI_PROPERTIES" | cut -d'=' -f2)
		fi

		# Compute the checksums for the downloaded archives
		checksum_modules=$(md5sum $RPI_MODULES_ARCHIVE_NAME | cut -d' ' -f1)
		checksum_boot_files=$(md5sum $RPI_ARCHIVE_NAME | cut -d' ' -f1)
	
		# Check if the archives were downloaded correctly and then extract files
		if [[ $checksum_properties_modules = $checksum_modules && $checksum_properties_boot_files = $checksum_boot_files ]]; then
			tar -xf $RPI_ARCHIVE_NAME -C "${BUILD_DIR}"/boot --no-same-owner
			tar -xf $RPI_MODULES_ARCHIVE_NAME -C "${BUILD_DIR}"/lib/modules --no-same-owner
		else
			echo "Something went wrong while downloading the boot files - Aborting."
			exit 1
		fi
		rm $RPI_ARCHIVE_NAME
		rm $RPI_MODULES_ARCHIVE_NAME
		mv $RPI_PROPERTIES "${BUILD_DIR}"/boot
	fi

	# Add custom files for Raspberry Pi
	install -m 644 "${BASH_SOURCE%%/run.sh}"/files/cmdline.txt 			 "${BUILD_DIR}/boot/cmdline.txt"
	install -m 644 "${BASH_SOURCE%%/run.sh}"/files/${TARGET_ARCHITECTURE}/config.txt "${BUILD_DIR}/boot/config.txt"
	
	# Install Raspberry Pi boot files: start*.elf, fixup*.dat, bootcode.bin and LICENCE.broadcom. 
	# These files are downloaded as a package from the Raspberry Pi apt repository.
	sed -i 's/deb /#deb /' "${BUILD_DIR}/etc/apt/sources.list"
	sed -i 's/#deb /deb /' "${BUILD_DIR}/etc/apt/sources.list.d/raspi.list"

chroot "${BUILD_DIR}" << EOF
	 apt-get update
	 apt-get install -y raspberrypi-bootloader --no-install-recommends
EOF

	sed -i 's/deb /#deb /' "${BUILD_DIR}/etc/apt/sources.list.d/raspi.list"
	sed -i 's/#deb /deb /' "${BUILD_DIR}/etc/apt/sources.list"

chroot "${BUILD_DIR}" << EOF
	 apt-get update
EOF

else
	echo "Raspberry Pi boot files won't be installed because CONFIG_RPI_BOOT_FILES is set to 'n'."
fi
