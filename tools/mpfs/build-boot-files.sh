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
: > "${sources}"
: > "${projects_json}"

if [ -n "${kernel_build}" ]; then
	mkdir -p "${BOOT}/mpfs-common"
	cp "${KERNEL_IMAGE}" "${BOOT}/mpfs-common/Image"
	src=$(readlink -f "${kernel_build}/source" 2> /dev/null || true)
	if [ -n "${src}" ] && git -C "${src}" rev-parse -q --verify HEAD > /dev/null 2>&1; then
		echo "linux: $(git -C "${src}" remote get-url origin 2> /dev/null || echo "${src}")" \
			"$(git -C "${src}" rev-parse --abbrev-ref HEAD) $(git -C "${src}" rev-parse HEAD) (${kernel_release})" >> "${sources}"
	else
		echo "linux: ${kernel_build} (${kernel_release})" >> "${sources}"
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
# copyright, in the Debian format: 08.export-stage/03.generate-license lists
# the package with its License and Source
cat > "${PKG}/usr/share/doc/adi-mpfs-boot/copyright" << 'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: adi-mpfs-boot
Source: https://github.com/analogdevicesinc/kuiper
 https://github.com/analogdevicesinc/linux
 https://github.com/linux4microchip/u-boot-mchp
 https://github.com/linux4microchip/meta-mchp
 https://github.com/polarfire-soc/hart-software-services
Comment: Built by tools/mpfs/build-boot-files.sh of the Kuiper repository; the
 repositories and the commits of the files are in
 /usr/share/doc/adi-mpfs-boot/sources.txt.

Files: boot/mpfs-common/Image boot/*/*/mss.dtb
Copyright: The Linux kernel contributors, Analog Devices, Inc.
License: GPL-2.0
Comment: The kernel and the devicetrees of ADI Linux.

Files: boot/*/payload.bin
Copyright: The U-Boot contributors, Microchip Technology Inc.
License: GPL-2.0 and MIT
Comment: U-Boot of u-boot-mchp (GPL-2.0) in the HSS payload format of the
 hss-payload-generator of the Hart Software Services (MIT).

Files: boot/*/uboot.env
Copyright: Microchip Technology Inc.
License: MIT
Comment: The U-Boot environment of the board in meta-mchp.

Files: boot/*/boot.scr boot/kuiper.json
Copyright: Analog Devices, Inc.
License: BSD-3-Clause

License: GPL-2.0
 On Debian systems, the complete text of the GNU General Public License
 version 2 can be found in /usr/share/common-licenses/GPL-2.

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

License: BSD-3-Clause
 On Debian systems, the complete text of the BSD 3-clause license can be
 found in /usr/share/common-licenses/BSD.
EOF
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
