#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# Builds the Kuiper image of the Microchip PolarFire SoC boards in one go:
#   1. the kernel and the devicetrees: ADI Linux (LINUX_URL, LINUX_BRANCH)
#      fetched in linux and built with adi_mpfs_defconfig in linux-build of
#      the build temp directory, unless -k (an existing build) or -n,
#   2. the ADI packages for riscv64 (tools/riscv64/build-adi-packages.sh; the
#      ones already built are not built again),
#   3. the boot files of the boards, adi-mpfs-boot (build-boot-files.sh),
#      both into the local package repository kuiper-build-temp/adi-local-repo,
#   4. the settings of mpfs.config in config (ci/modify_config.sh), and
#      ADI_EVAL_BOARD and CARRIER with -p,
#   5. the image, as any Kuiper image: sudo build-docker.sh.
# First it checks the build host; it only prints what is missing, -i installs
# it. config is changed in place, as the Kuiper CI does: git diff config shows
# the settings, git checkout config restores them.
# The build files are in the build temp directory (KUIPER_BUILD_TEMP, default
# kuiper-build-temp, relative to 'kuiper' folder, in .gitignore), the image in
# kuiper-volume, as any Kuiper image; removing kuiper-build-temp cleans the
# build.
#
# Usage: tools/mpfs/build-image.sh [-k <ADI Linux build> | -n] [-L <repository>] [-B <branch>] [-p <eval board>] [-s] [-i] [-c]
#   -k  an existing ADI Linux build (O=) of the kernel Image and the devicetrees:
#       make O=<build> ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- adi_mpfs_defconfig Image dtbs
#   -n  without the kernel and the devicetrees
#   -L  the ADI Linux repository to build the kernel from, a URL or a local
#       clone (LINUX_URL; default: https://github.com/analogdevicesinc/linux.git)
#   -B  its branch (LINUX_BRANCH; default: staging/main-mpfs)
#   -p  configure the image for this project, e.g. fmcomms2 (ADI_EVAL_BOARD;
#       CARRIER: mpfs_video_kit); default: not configured, as the Kuiper images
#   -s  stop before the image: the kernel, the packages, the boot files and
#       config only
#   -i  install what the build host is missing (sudo apt install, the riscv64
#       binfmt); without -i, only what is missing is printed
#   -c  only check the build host

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KUIPER_DIR=$(cd "${HERE}/../.." && pwd)
CROSS_COMPILE=${CROSS_COMPILE:-riscv64-linux-gnu-}
LINUX_URL=${LINUX_URL:-https://github.com/analogdevicesinc/linux.git}
LINUX_BRANCH=${LINUX_BRANCH:-staging/main-mpfs}
LINUX_DEFCONFIG=adi_mpfs_defconfig

error() { echo "ERROR: $*" >&2; exit 1; }
usage() { sed -n '/^# Usage/,/^#   -c/p' "$0"; exit 2; }
step() { echo; echo "==> $*"; }

kernel_build=
no_kernel=
eval_board=
stop_before_image=
install=
check_only=
while getopts "k:nL:B:p:sich" opt; do
	case $opt in
		k) kernel_build=$(realpath "$OPTARG") ;;
		n) no_kernel=1 ;;
		L) LINUX_URL=$OPTARG ;;
		B) LINUX_BRANCH=$OPTARG ;;
		p) eval_board=$OPTARG ;;
		s) stop_before_image=1 ;;
		i) install=1 ;;
		c) check_only=1 ;;
		*) usage ;;
	esac
done
[ $OPTIND -gt $# ] || usage
[ -z "${kernel_build}" ] || [ -z "${no_kernel}" ] || error "-k or -n, not both"
[ -z "${eval_board}" ] || [ -z "${no_kernel}" ] || error "-p needs the kernel (no -n)"
# A local clone as an absolute path, as git fetches from the linux directory of
# the build temp directory
[ ! -d "${LINUX_URL}" ] || LINUX_URL=$(realpath "${LINUX_URL}")

# -- the build host -------------------------------------------------------------
HOST_PACKAGES="mmdebstrap uidmap qemu-user-static binfmt-support
	debian-archive-keyring git make build-essential gcc-riscv64-linux-gnu bison
	flex bc libssl-dev libgnutls28-dev libyaml-dev libelf-dev uuid-dev dpkg-dev"
[ -n "${stop_before_image}" ] || HOST_PACKAGES+=" docker.io"
missing_packages() {
	local p m=
	for p in ${HOST_PACKAGES}; do
		if [ "${p}" = docker.io ]; then
			# any docker installation
			command -v docker > /dev/null || m+=" ${p}"
		else
			dpkg-query -W -f='${Status}' "${p}" 2> /dev/null | grep -q "install ok installed" || m+=" ${p}"
		fi
	done
	echo "${m}"
}
missing=$(missing_packages)
if [ -n "${missing}" ] && [ -n "${install}" ]; then
	echo "Installing:${missing}"
	sudo apt-get update
	sudo apt-get install -y ${missing}
	missing=$(missing_packages)
fi
[ -z "${missing}" ] || error "missing on the build host:${missing}
    sudo apt install${missing}    (or tools/mpfs/build-image.sh -i)"
if [ ! -e /proc/sys/fs/binfmt_misc/qemu-riscv64 ] && [ -n "${install}" ]; then
	echo "Enabling the riscv64 binfmt"
	sudo update-binfmts --enable qemu-riscv64 || sudo systemctl restart systemd-binfmt
fi
[ -e /proc/sys/fs/binfmt_misc/qemu-riscv64 ] || error "no riscv64 binfmt (qemu-user-static, binfmt-support):
    sudo update-binfmts --enable qemu-riscv64    (or tools/mpfs/build-image.sh -i)"
echo "Build host: OK"
[ -z "${check_only}" ] || exit 0

# -- the steps ------------------------------------------------------------------
cd "${KUIPER_DIR}"

if [ -z "${kernel_build}${no_kernel}" ]; then
	step "The kernel: ${LINUX_URL} ${LINUX_BRANCH}"
	build_temp=$(realpath -m "${KUIPER_BUILD_TEMP:-kuiper-build-temp}")
	linux_src=${build_temp}/linux
	kernel_build=${build_temp}/linux-build
	log=${build_temp}/linux-build.log
	# The last commit of the branch only; the build is kept, so a new commit
	# only rebuilds what it changes
	[ -d "${linux_src}/.git" ] || git init -q "${linux_src}"
	if git -C "${linux_src}" remote get-url origin > /dev/null 2>&1; then
		git -C "${linux_src}" remote set-url origin "${LINUX_URL}"
	else
		git -C "${linux_src}" remote add origin "${LINUX_URL}"
	fi
	git -C "${linux_src}" fetch -q --depth 1 origin \
		"+refs/heads/${LINUX_BRANCH}:refs/remotes/origin/${LINUX_BRANCH}"
	git -C "${linux_src}" checkout -q -f -B "${LINUX_BRANCH}" "origin/${LINUX_BRANCH}"
	echo "$(git -C "${linux_src}" log -1 --format='%h %s')"
	mkdir -p "${kernel_build}"
	(
		make -C "${linux_src}" O="${kernel_build}" ARCH=riscv CROSS_COMPILE="${CROSS_COMPILE}" ${LINUX_DEFCONFIG}
		make -C "${linux_src}" O="${kernel_build}" ARCH=riscv CROSS_COMPILE="${CROSS_COMPILE}" -j"$(nproc)" Image dtbs
	) > "${log}" 2>&1 || { tail -20 "${log}"; error "the kernel build failed, see ${log}"; }
	echo "Kernel: ${kernel_build} ($(cat "${kernel_build}/include/config/kernel.release"))"
fi

step "The ADI packages for riscv64"
"${KUIPER_DIR}/tools/riscv64/build-adi-packages.sh"

step "The PolarFire SoC boot files"
if [ -n "${no_kernel}" ]; then
	"${HERE}/build-boot-files.sh" -n
else
	"${HERE}/build-boot-files.sh" -k "${kernel_build}"
fi

step "The settings of tools/mpfs/mpfs.config in config"
settings=$(grep -E '^[A-Z0-9_]+=' "${HERE}/mpfs.config" | tr '\n' ' ')
settings+=" ADI_EVAL_BOARD=${eval_board} CARRIER=${eval_board:+mpfs_video_kit}"
ci/modify_config.sh ./config "${settings}"

if [ -n "${stop_before_image}" ]; then
	echo
	echo "Ready for the image: sudo bash build-docker.sh"
	exit 0
fi

step "The image: sudo bash build-docker.sh"
sudo bash build-docker.sh
