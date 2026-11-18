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
LIGHT_BLUE="`tput setaf 6`"
RESET="`tput sgr0`"

export LOG_FILE="kuiper-volume/build.log"
export GITHUB_ANALOG_DEVICES="https://github.com/analogdevicesinc"
export TARGET_ARCHITECTURE=${TARGET_ARCHITECTURE:-armhf}
export BUILD_DIR=${TARGET_ARCHITECTURE}_rootfs
export BUILD_DATE=${BUILD_DATE:-$(date -u +%Y-%m-%d)}
export IMG_FILE="image_${BUILD_DATE}-ADI-Kuiper-Linux-${TARGET_ARCHITECTURE}.img"
export NUM_JOBS=${NUM_JOBS:-$(nproc)}
export HOSTNAME=${HOSTNAME:-analog}
export DEBIAN_SNAPSHOT=${DEBIAN_SNAPSHOT:-""}
export DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}

export KUIPER_VERSION=${KUIPER_VERSION:-unknown}
export KUIPER_COMMIT=${KUIPER_COMMIT:-unknown}
export KUIPER_VARIANT=${KUIPER_VARIANT:-custom}

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
export CONFIG_ARCH_MPFS=${CONFIG_ARCH_MPFS:-n}

export ADI_EVAL_BOARD=${ADI_EVAL_BOARD:-""}
export CARRIER=${CARRIER:-""}
export EXTRA_SCRIPT=${EXTRA_SCRIPT:-""}
export INSTALL_RPI_PACKAGES=${INSTALL_RPI_PACKAGES:-n}
export ADI_LOCAL_REPO=${ADI_LOCAL_REPO:-""}

# Packages of the package lists that Debian has no build of for the target
# architecture, and what is installed instead (<package>=<substitute>)
if [ "${TARGET_ARCHITECTURE}" = riscv64 ]; then
	export PACKAGE_SUBSTITUTES=${PACKAGE_SUBSTITUTES:-"chromium=firefox-esr"}
else
	export PACKAGE_SUBSTITUTES=${PACKAGE_SUBSTITUTES:-""}
fi

# Check if architecture is supported
if [[ ! ${TARGET_ARCHITECTURE} = armhf && ! ${TARGET_ARCHITECTURE} = arm64 && ! ${TARGET_ARCHITECTURE} = riscv64 ]]; then
	echo "Unsupported architecture ${TARGET_ARCHITECTURE}"
	exit 1
fi

# Check that the boot files match the architecture: riscv64 (PolarFire SoC)
# has none of the Raspberry Pi, Intel and Xilinx ones, and the PolarFire SoC
# ones are riscv64 only
if [ "${TARGET_ARCHITECTURE}" = riscv64 ]; then
	for boot_files in CONFIG_RPI_BOOT_FILES CONFIG_ARCH_ZYNQ CONFIG_ARCH_ZYNQMP \
		CONFIG_ARCH_VERSAL CONFIG_ARCH_ARRIA10 CONFIG_ARCH_CYCLONE5; do
		if [ "${!boot_files}" = y ]; then
			echo "${boot_files}=y is not supported on riscv64"
			exit 1
		fi
	done
elif [ "${CONFIG_ARCH_MPFS}" = y ]; then
	echo "CONFIG_ARCH_MPFS=y needs TARGET_ARCHITECTURE=riscv64"
	exit 1
fi

# Validate the snapshot timestamp
if [ -n "${DEBIAN_SNAPSHOT}" ]; then
	if [[ ! ${DEBIAN_SNAPSHOT} =~ ^[0-9]{8}(T[0-9]{6}Z)?$ ]]; then
		echo "Invalid DEBIAN_SNAPSHOT '${DEBIAN_SNAPSHOT}'"
		echo "Expected format YYYYMMDD or YYYYMMDDTHHMMSSZ, e.g. 20260615T000000Z"
		exit 1
	fi
fi

# Save logs with timestamps in build.log
exec > >(TZ=UTC-3 ts '[%b %d %H:%M:%S]' | tee -ia "${LOG_FILE}") 2>&1

echo "${LIGHT_BLUE}Building Kuiper with Debian ${DEBIAN_VERSION} for architecture ${TARGET_ARCHITECTURE}${RESET}"

# Print a package list with PACKAGE_SUBSTITUTES applied
# Usage: package_list <list>
package_list() {
	local substitute sed_args=(-e '')

	for substitute in ${PACKAGE_SUBSTITUTES}; do
		sed_args+=(-e "s/^${substitute%%=*}\$/${substitute#*=}/")
	done
	sed "${sed_args[@]}" "$1"
}
export -f package_list

# Install packages for a stage
# Usage: install_packages <script_dir>
# Looks for 'packages' and 'packages-with-recommends' in <script_dir>/00.install-packages/
# The package lists go to apt-get in the chroot on its standard input, nothing
# is written into the chroot for them
install_packages() {
	local script_dir="$1"
	local packages_dir="${script_dir}/00.install-packages"
	local packages

	if [ -e "${packages_dir}/packages" ]; then
		packages=$(package_list "${packages_dir}/packages")
		printf '%s\n' "${packages}" | chroot "${BUILD_DIR}" xargs \
			apt-get install --no-install-recommends -y
	fi

	if [ -e "${packages_dir}/packages-with-recommends" ]; then
		packages=$(package_list "${packages_dir}/packages-with-recommends")
		printf '%s\n' "${packages}" | chroot "${BUILD_DIR}" xargs \
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
