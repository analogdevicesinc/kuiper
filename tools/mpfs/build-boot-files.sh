#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# Builds the boot files of the Microchip PolarFire SoC boards (boards/*) as
# the adi-mpfs-boot package, which 06.boot-partition/01.adi-boot-files
# installs with CONFIG_ARCH_MPFS=y, into the local package repository of
# ADI_LOCAL_REPO (config). Its files in /boot, as the boot files of the other
# architectures:
#   mpfs-common/Image                          the kernel, of an ADI Linux build
#   <board folder>/payload.bin                 U-Boot in the HSS payload format,
#                                              the preloader of the projects
#   <board folder>/boot.scr, uboot.env         the boot script and the U-Boot
#                                              environment of the board
#   <target>/<specific_folder>/mss.dtb         the devicetree of each project
#   kuiper.json                                the projects, for
#                                              configure-setup.sh
# configure-setup.sh copies the kernel and the files of a project (mss.dtb,
# boot.scr, uboot.env) to the root of the boot partition, and
# 08.export-stage/04.export-image writes the payload to the bootloader
# partition, which the HSS of the board boots.
#
# U-Boot, its environment and the payload are built as the Microchip Yocto BSP
# (meta-mchp) does for the board, from the repositories at the commits of
# boards/<board>/board.conf, fetched in mpfs-boot-work of the build temp
# directory (KUIPER_BUILD_TEMP, default kuiper-build-temp, relative to 'kuiper'
# folder, in .gitignore), emptied at the start of each run. The
# kernel and the devicetrees come from an ADI Linux build:
#   make O=<build> ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- adi_mpfs_defconfig Image dtbs
# The licenses of these sources (the kernel, U-Boot, meta-mchp, the HSS and
# Kuiper) go into the package as tools/collect-licenses.sh collects them from
# the sources: their license files and the copyright file.
#
# Usage: tools/mpfs/build-boot-files.sh -k <ADI Linux build> | -n
#   -k  the ADI Linux build (O=) of the kernel Image and the devicetrees
#   -n  without the kernel and the devicetrees: the boot files of the boards
#       only (Image and mss.dtb copied to the boot partition later)
# Needs: git, make, gcc, gcc-riscv64-linux-gnu, bison, flex, bc, libssl-dev,
#   libgnutls28-dev, libyaml-dev, libelf-dev, uuid-dev, dpkg-dev

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KUIPER_DIR=$(cd "${HERE}/../.." && pwd)
CROSS_COMPILE=${CROSS_COMPILE:-riscv64-linux-gnu-}

error() { echo "ERROR: $*" >&2; exit 1; }
usage() { sed -n '/^# Usage/,/^#       only/p' "$0"; exit 2; }

kernel_build=
no_kernel=
while getopts "k:nh" opt; do
	case $opt in
		k) kernel_build=$(realpath "$OPTARG") ;;
		n) no_kernel=1 ;;
		*) usage ;;
	esac
done
[ -n "${kernel_build}${no_kernel}" ] || usage
[ -z "${kernel_build}" ] || [ -z "${no_kernel}" ] || error "-k or -n, not both"

cd "${KUIPER_DIR}"
APT_DIR=$(realpath -m "${ADI_LOCAL_REPO:-kuiper-build-temp/adi-local-repo}")
WORK=$(realpath -m "${KUIPER_BUILD_TEMP:-kuiper-build-temp}")/mpfs-boot-work
PKG=${WORK}/adi-mpfs-boot
BOOT=${PKG}/boot

if [ -n "${kernel_build}" ]; then
	KERNEL_IMAGE=${kernel_build}/arch/riscv/boot/Image
	KERNEL_DTB_DIR=${kernel_build}/arch/riscv/boot/dts/microchip
	[ -f "${KERNEL_IMAGE}" ] || error "no ${KERNEL_IMAGE} (make Image dtbs)"
	kernel_release=$(cat "${kernel_build}/include/config/kernel.release" 2> /dev/null || echo unknown)
fi

# A shallow fetch of one commit of a repository
fetch() {
	local url=$1 commit=$2 dir=$3
	git init -q "${dir}"
	git -C "${dir}" fetch -q --depth 1 "${url}" "${commit}"
	git -C "${dir}" -c advice.detachedHead=false checkout -q FETCH_HEAD
	[ "$(git -C "${dir}" rev-parse HEAD)" = "${commit}" ] || error "${url}: not ${commit}"
}

rm -rf "${WORK}"
mkdir -p "${WORK}" "${BOOT}" "${APT_DIR}"
sources=${WORK}/sources.txt
projects_json=${WORK}/projects.json
licenses=${WORK}/licenses.list
: > "${sources}"
: > "${projects_json}"
# The sources of the package for tools/collect-licenses.sh:
# <name>|<source dir>|<URL>|<commit>|<files in the package>|<license files>
echo "kuiper|${KUIPER_DIR}|https://github.com/analogdevicesinc/kuiper|$(git -C "${KUIPER_DIR}" rev-parse HEAD 2> /dev/null || true)|boot/*/boot.scr boot/kuiper.json|LICENSE" > "${licenses}"

if [ -n "${kernel_build}" ]; then
	mkdir -p "${BOOT}/mpfs-common"
	cp "${KERNEL_IMAGE}" "${BOOT}/mpfs-common/Image"
	src=$(readlink -f "${kernel_build}/source" 2> /dev/null || true)
	if [ -n "${src}" ] && git -C "${src}" rev-parse -q --verify HEAD > /dev/null 2>&1; then
		echo "linux: $(git -C "${src}" remote get-url origin 2> /dev/null || echo "${src}")" \
			"$(git -C "${src}" rev-parse --abbrev-ref HEAD) $(git -C "${src}" rev-parse HEAD) (${kernel_release})" >> "${sources}"
		echo "linux|${src}|$(git -C "${src}" remote get-url origin 2> /dev/null || echo "${src}")|$(git -C "${src}" rev-parse HEAD)|boot/mpfs-common/Image boot/*/*/mss.dtb|COPYING LICENSES/preferred/GPL-2.0 LICENSES/exceptions/Linux-syscall-note" >> "${licenses}"
	else
		echo "linux: ${kernel_build} (${kernel_release})" >> "${sources}"
		# an in-tree build: the source is the build
		echo "linux|${src:-${kernel_build}}|${kernel_build}||boot/mpfs-common/Image boot/*/*/mss.dtb|COPYING LICENSES/preferred/GPL-2.0 LICENSES/exceptions/Linux-syscall-note" >> "${licenses}"
	fi
fi

for board_dir in "${HERE}"/boards/*/; do
	board=$(basename "${board_dir}")
	(
		source "${board_dir}/board.conf"
		work=${WORK}/${board}
		out=${BOOT}/${BOARD_FOLDER}
		mkdir -p "${work}" "${out}"
		echo "==> ${board}"

		# meta-mchp: the board files and the U-Boot commit of its recipe
		fetch "${META_MCHP_URL}" "${META_MCHP_COMMIT}" "${work}/meta-mchp"
		recipe=${work}/meta-mchp/meta-mchp-common/recipes-bsp/u-boot/u-boot-mchp_${UBOOT_VERSION}.bb
		mchp_files=${work}/meta-mchp/meta-mchp-polarfire-soc/meta-mchp-polarfire-soc-bsp/recipes-bsp/u-boot/files
		uboot_commit=$(sed -n 's/^SRCREV[[:space:]]*=[[:space:]]*"\(.*\)"/\1/p' "${recipe}")
		[ -n "${uboot_commit}" ] || error "no SRCREV in ${recipe}"

		# U-Boot, with the configuration fragment of the board; reproducible,
		# with the date of its commit as the build date
		fetch "${UBOOT_URL}" "${uboot_commit}" "${work}/u-boot"
		export SOURCE_DATE_EPOCH=$(git -C "${work}/u-boot" log -1 --format=%ct)
		log=${work}/u-boot.log
		(
			cd "${work}/u-boot"
			make "${UBOOT_DEFCONFIG}"
			scripts/kconfig/merge_config.sh -m .config "${mchp_files}/${MCHP_BOARD}/${MCHP_BOARD}.cfg"
			make olddefconfig
			make -j"$(nproc)" CROSS_COMPILE="${CROSS_COMPILE}"
		) > "${log}" 2>&1 || { tail -20 "${log}"; error "U-Boot build failed, see ${log}"; }
		grep -q "^CONFIG_ENV_IS_IN_FAT=y" "${work}/u-boot/.config" || error "the U-Boot environment is not in FAT"

		# payload.bin: U-Boot in the HSS payload format, with the uboot.yaml of meta-mchp
		fetch "${HSS_URL}" "${HSS_COMMIT}" "${work}/hss"
		make -C "${work}/hss/tools/hss-payload-generator" > "${work}/hss-payload-generator.log" 2>&1 || \
			error "hss-payload-generator build failed, see ${work}/hss-payload-generator.log"
		cp "${work}/u-boot/u-boot.bin" "${mchp_files}/${MCHP_BOARD}/uboot.yaml" "${work}/"
		(cd "${work}" && "${work}/hss/tools/hss-payload-generator/hss-payload-generator" \
			-c uboot.yaml -v "${out}/payload.bin") > "${work}/payload.log" 2>&1 || \
			error "payload.bin failed, see ${work}/payload.log"

		# uboot.env: the environment of meta-mchp, the root file system on UBOOT_ENV_ROOTPART
		{
			grep -v '^rootpart=' "${mchp_files}/envs/${MCHP_BOARD}.txt"
			echo "rootpart=${UBOOT_ENV_ROOTPART}"
		} > "${work}/uboot-env.txt"
		"${work}/u-boot/tools/mkenvimage" -s "${UBOOT_ENV_SIZE}" "${work}/uboot-env.txt" -o "${out}/uboot.env"

		# boot.scr: the boot script of the board
		"${work}/u-boot/tools/mkimage" -A riscv -T script -C none -n "Kuiper ${KUIPER_BOARD}" \
			-d "${board_dir}/boot.cmd" "${out}/boot.scr" > /dev/null

		cat >> "${sources}" <<- EOF
		${board}: meta-mchp ${META_MCHP_URL} ${META_MCHP_COMMIT}
		${board}: u-boot ${UBOOT_URL} ${uboot_commit} (${UBOOT_DEFCONFIG} + ${MCHP_BOARD}.cfg, rootpart=${UBOOT_ENV_ROOTPART})
		${board}: hss ${HSS_URL} ${HSS_COMMIT} (hss-payload-generator)
		EOF
		cat >> "${licenses}" <<- EOF
		${board}/u-boot|${work}/u-boot|${UBOOT_URL}|${uboot_commit}|boot/${BOARD_FOLDER}/payload.bin|${UBOOT_LICENSE_FILES}
		${board}/hss|${work}/hss|${HSS_URL}|${HSS_COMMIT}|boot/${BOARD_FOLDER}/payload.bin|${HSS_LICENSE_FILES}
		${board}/meta-mchp|${work}/meta-mchp|${META_MCHP_URL}|${META_MCHP_COMMIT}|boot/${BOARD_FOLDER}/uboot.env|${META_MCHP_LICENSE_FILES}
		EOF

		# the projects: the devicetrees, and their entries of kuiper.json
		[ -z "${no_kernel}" ] || exit 0
		read -r -a projects <<< "$(echo ${PROJECTS})"
		for ((i = 0; i < ${#projects[@]}; i += 3)); do
			name=${projects[i]} target=${projects[i + 1]} dts=${projects[i + 2]}
			[ -f "${KERNEL_DTB_DIR}/${dts}.dtb" ] || error "no ${KERNEL_DTB_DIR}/${dts}.dtb"
			mkdir -p "${BOOT}/${target}/${dts}"
			cp "${KERNEL_DTB_DIR}/${dts}.dtb" "${BOOT}/${target}/${dts}/mss.dtb"
			cat >> "${projects_json}" <<- EOF
			    {
			      "name": "${name}",
			      "platform": "microchip",
			      "architecture": "mpfs",
			      "board": "${KUIPER_BOARD}",
			      "kernel": "/boot/mpfs-common/Image",
			      "preloader": "/boot/${BOARD_FOLDER}/payload.bin",
			      "files": [
			        {
			          "path": "/boot/${target}/${dts}/mss.dtb"
			        },
			        {
			          "path": "/boot/${BOARD_FOLDER}/boot.scr"
			        },
			        {
			          "path": "/boot/${BOARD_FOLDER}/uboot.env"
			        }
			      ]
			    },
			EOF
		done
	)
done

# kuiper.json, in the format of the Kuiper boot files
{
	echo "{"
	echo "  \"version\": \"0.1.0\","
	echo "  \"projects\": ["
	sed '$ s/^    },$/    }/' "${projects_json}"
	echo "  ]"
	echo "}"
} > "${BOOT}/kuiper.json"

# The package: the version is the date and the kernel commit
version=$(date -u +%Y.%m.%d)
if [ -n "${kernel_build}" ]; then
	version+="+$(sed -n 's/^linux: .* \([0-9a-f]\{7\}\)[0-9a-f]* (.*/\1/p' "${sources}")"
fi
mkdir -p "${PKG}/DEBIAN" "${PKG}/usr/share/doc/adi-mpfs-boot"
cp "${sources}" "${PKG}/usr/share/doc/adi-mpfs-boot/sources.txt"
# copyright and the license files of the sources, from the sources
"${KUIPER_DIR}/tools/collect-licenses.sh" -p adi-mpfs-boot \
	-o "${PKG}/usr/share/doc/adi-mpfs-boot" "${licenses}"
cat > "${PKG}/DEBIAN/control" << EOF
Package: adi-mpfs-boot
Version: ${version}-1
Architecture: all
Maintainer: Analog Devices, Inc.
Section: kernel
Priority: optional
Description: Boot files of the Microchip PolarFire SoC boards for Kuiper
 The kernel, the devicetrees of the projects, U-Boot (HSS payload), the boot
 script and the U-Boot environment of the PolarFire SoC boards, in /boot, with
 kuiper.json for configure-setup.sh. Built by tools/mpfs/build-boot-files.sh
 of the Kuiper repository; the sources are in
 /usr/share/doc/adi-mpfs-boot/sources.txt.
EOF
rm -f "${APT_DIR}"/adi-mpfs-boot_*.deb
dpkg-deb --root-owner-group -Zxz --build "${PKG}" "${APT_DIR}/adi-mpfs-boot_${version}-1_all.deb" > /dev/null
(cd "${APT_DIR}" && dpkg-scanpackages --multiversion . > Packages 2> /dev/null && gzip -kf Packages)

echo
cat "${sources}"
(cd "${BOOT}" && find . -type f | sort | sed 's|^\./|/boot/|')
echo "Package: ${APT_DIR}/adi-mpfs-boot_${version}-1_all.deb"
