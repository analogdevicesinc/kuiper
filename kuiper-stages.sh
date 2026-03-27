#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

set -e
source config

# Declare ANSI escape codes to color the output in the terminal
MAGENTA="`tput setaf 5`"
RESET="`tput sgr0`"

export LOG_FILE="kuiper-volume/build.log"
export GITHUB_ANALOG_DEVICES="https://github.com/analogdevicesinc"
export ADI_REPOS="ADI_repos_git_info.txt"
export TARGET_ARCHITECTURE=${TARGET_ARCHITECTURE:-armhf}
export BUILD_DIR=${TARGET_ARCHITECTURE}_rootfs
export IMG_FILE="image_"$(date +%Y-%m-%d)"-ADI-Kuiper-Linux-$TARGET_ARCHITECTURE.img"
export NUM_JOBS=${NUM_JOBS:-$(nproc)}

export CONFIG_DESKTOP=${CONFIG_DESKTOP:-n}
export CONFIG_LIBIIO=${CONFIG_LIBIIO:-n}
export CONFIG_PYADI=${CONFIG_PYADI:-n}
export CONFIG_LIBM2K=${CONFIG_LIBM2K:-n}
export CONFIG_LIBAD9166_IIO=${CONFIG_LIBAD9166_IIO:-n}
export CONFIG_LIBAD9361_IIO=${CONFIG_LIBAD9361_IIO:-n}
export CONFIG_IIO_OSCILLOSCOPE=${CONFIG_IIO_OSCILLOSCOPE:-n}
export CONFIG_IIO_FM_RADIO=${CONFIG_IIO_FM_RADIO:-n}
export CONFIG_FRU_TOOLS=${CONFIG_FRU_TOOLS:-n}
export CONFIG_SCOPY=${CONFIG_SCOPY:-n}
export CONFIG_GNURADIO=${CONFIG_GNURADIO:-n}
export CONFIG_GRM2K=${CONFIG_GRM2K:-n}
export CONFIG_JESD_EYE_SCAN_GTK=${CONFIG_JESD_EYE_SCAN_GTK:-n}
export CONFIG_COLORIMETER=${CONFIG_COLORIMETER:-n}
export CONFIG_LINUX_SCRIPTS=${CONFIG_LINUX_SCRIPTS:-n}
export CONFIG_RPI_BOOT_FILES=${CONFIG_RPI_BOOT_FILES:-n}
export EXPORT_SOURCES=${EXPORT_SOURCES:-n}

export CONFIG_LIBIIO_CMAKE_ARGS=${CONFIG_LIBIIO_CMAKE_ARGS:-""}
export CONFIG_LIBM2K_CMAKE_ARGS=${CONFIG_LIBM2K_CMAKE_ARGS:-""}
export CONFIG_LIBAD9166_IIO_CMAKE_ARGS=${CONFIG_LIBAD9166_IIO_CMAKE_ARGS:-""}
export CONFIG_LIBAD9361_IIO_CMAKE_ARGS=${CONFIG_LIBAD9361_IIO_CMAKE_ARGS:-""}
export CONFIG_IIO_OSCILLOSCOPE_CMAKE_ARGS=${CONFIG_IIO_OSCILLOSCOPE_CMAKE_ARGS:-""}
export CONFIG_JESD_EYE_SCAN_GTK_CMAKE_ARGS=${CONFIG_JESD_EYE_SCAN_GTK_CMAKE_ARGS:-""}
export CONFIG_GRM2K_CMAKE_ARGS=${CONFIG_GRM2K_CMAKE_ARGS:-""}

export BRANCH_LIBIIO=${BRANCH_LIBIIO:-main}
export BRANCH_PYADI=${BRANCH_PYADI:-main}
export BRANCH_LIBM2K=${BRANCH_LIBM2K:-main}
export BRANCH_LIBAD9361_IIO=${BRANCH_LIBAD9361_IIO:-main}
export BRANCH_LIBAD9166_IIO=${BRANCH_LIBAD9166_IIO:-main}
export BRANCH_IIO_OSCILLOSCOPE=${BRANCH_IIO_OSCILLOSCOPE:-main}
export BRANCH_IIO_FM_RADIO=${BRANCH_IIO_FM_RADIO:-main}
export BRANCH_FRU_TOOLS=${BRANCH_FRU_TOOLS:-main}
export BRANCH_JESD_EYE_SCAN_GTK=${BRANCH_JESD_EYE_SCAN_GTK:-main}
export BRANCH_COLORIMETER=${BRANCH_COLORIMETER:-main}
export BRANCH_GRM2K=${BRANCH_GRM2K:-main}
export BRANCH_LINUX_SCRIPTS=${BRANCH_LINUX_SCRIPTS:-kuiper2.0}

export CONFIG_ARCH_ZYNQ=${CONFIG_ARCH_ZYNQ:-n}
export CONFIG_ARCH_ZYNQMP=${CONFIG_ARCH_ZYNQMP:-n}
export CONFIG_ARCH_VERSAL=${CONFIG_ARCH_VERSAL:-n}
export CONFIG_ARCH_ARRIA10=${CONFIG_ARCH_ARRIA10:-n}
export CONFIG_ARCH_CYCLONE5=${CONFIG_ARCH_CYCLONE5:-n}

export ADI_EVAL_BOARD=${ADI_EVAL_BOARD:-""}
export CARRIER=${CARRIER:-""}
export EXTRA_SCRIPT=${EXTRA_SCRIPT:-""}
export INSTALL_RPI_PACKAGES=${INSTALL_RPI_PACKAGES:-n}

# Check if architecture is supported
if [[ ! ${TARGET_ARCHITECTURE} = armhf && ! ${TARGET_ARCHITECTURE} = arm64 ]]; then
	echo "Unsupported architecture ${TARGET_ARCHITECTURE}"
	exit 1
fi

# Save logs with timestamps in build.log
exec > >(TZ=UTC-3 ts '[%b %d %H:%M:%S]' | tee -ia "${LOG_FILE}") 2>&1

echo "${LIGHT_BLUE}Building Kuiper with Debian ${DEBIAN_VERSION} for architecture ${TARGET_ARCHITECTURE}${RESET}"

# Install packages for a stage
# Usage: install_packages <script_dir>
# Looks for 'packages' and 'packages-with-recommends' in <script_dir>/00.install-packages/
install_packages() {
	local script_dir="$1"
	local packages_dir="${script_dir}/00.install-packages"

	if [ -e "${packages_dir}/packages" ]; then
		chroot "${BUILD_DIR}" xargs -a "${packages_dir}/packages" \
			apt-get install --no-install-recommends -y
	fi

	if [ -e "${packages_dir}/packages-with-recommends" ]; then
		chroot "${BUILD_DIR}" xargs -a "${packages_dir}/packages-with-recommends" \
			apt-get install -y
	fi
}
export -f install_packages

# Run every 'run.sh' script inside 'stages' directory in alphanumeric order.
# Each stage is responsible for installing its own packages using
# install_packages.
for script in $(find stages -type f -name run.sh | sort); do
	echo "${MAGENTA}Start stage ${script:7:-7}${RESET}"
	bash -e ${script}
	echo "End stage ${script:7:-7}"
done
