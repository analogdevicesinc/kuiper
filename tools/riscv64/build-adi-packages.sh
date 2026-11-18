#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# Builds the ADI packages that the 05.adi-tools stages install (ADI_PACKAGES)
# for riscv64, which the ADI Package Repository has no builds of, into a local
# package repository for ADI_LOCAL_REPO (config). It does what the ADI CI does
# for the ADI Package Repository (shared-actions deb-generator-action: the
# packaging/debian of each repository, the build dependencies, debuild), in
# adi-packages/build-pkgs.sh, in a Debian build environment of the Debian
# release and snapshot of the Kuiper config, made by mmdebstrap and thrown away
# after the build, without root:
#   - by default cross-compiled, in an amd64 environment with the riscv64
#     cross compiler (dpkg-buildpackage -a riscv64);
#   - "native" packages (those that cannot be cross-compiled: Python
#     extensions, GNU Radio) in a riscv64 environment, under qemu user
#     emulation, as the ADI CI builds arm64 in an arm64 container.
# Each package can depend on the ones built before it, and on the ones of the
# repository. A package already in the repository at its version (version +
# commit) is not built again, so a saved repository can be reused.
#
# Differences from the ADI packages (adi-packages/):
#   - libm2k.sh: no libm2k-csharp, Debian has no riscv64 Mono runtime;
#   - iio-oscilloscope.sh: the ADI package repackages the AppImage, which has
#     no riscv64 build; built from source with the debian/ of the repository,
#     under the name the stage installs;
#   - gt/: the packaging of the USB Gadget Tool, which adi-scripts depends on
#     and whose ADI packaging is not public.
# Scopy (an AppImage too) is not built.
#
# The build files go to the build temp directory (KUIPER_BUILD_TEMP, default
# kuiper-build-temp, relative to 'kuiper' folder, in .gitignore): the sources
# and the inputs of the build environments in riscv64-packages. The build
# environments (the TMPDIR of mmdebstrap) go to kuiper-build-env-<uid>-<id of
# the work directory> in KUIPER_BUILD_ENV_TEMP (default: TMPDIR, or /tmp), as
# the root of the user namespace of mmdebstrap (the first subordinate uid of
# the user, /etc/subuid) must reach them: a home directory of mode 750, for
# example, does not let it pass. With KUIPER_BUILD_ENV_TEMP=kuiper-build-temp
# they are in the build temp directory too, when it can reach it: it is
# checked first, and the directory that it cannot pass is named (the
# permissions are not changed). Both are thrown away at the end, also when a
# build fails or is interrupted, and at the start, if a killed run left them;
# the files of the build environments belong to the subordinate ids, so they
# are removed in a user namespace (unshare).
#
# Usage: tools/riscv64/build-adi-packages.sh [<repository>...]
#   (default: all of ADI_PACKAGES; the repository: ADI_LOCAL_REPO, default
#   kuiper-build-temp/adi-local-repo, relative to 'kuiper' folder; the logs:
#   <repository>-logs)
# Needs: mmdebstrap, uidmap, qemu-user-static, binfmt-support,
#   debian-archive-keyring, git

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
KUIPER_DIR=$(cd "${HERE}/../.." && pwd)

error() { echo "ERROR: $*" >&2; exit 1; }

# The ADI packages: <repository> <commit> [native], in build order, at the
# head of the branch that the 05.adi-tools stages build from source; the
# repository is an ADI repository name or the URL of another repository
ADI_GITHUB=https://github.com/analogdevicesinc
ADI_PACKAGES="
	libad9361-iio b60f1770bf8466a90c09d63f127d7f0835c105cc
	libad9166-iio e53b453f58c28094d41a9a26df8b07291a24b096
	libm2k 6a31b3745aee6f544e63b2196a6171f92c2f43a2 native
	gr-m2k 5dfacf945d6c598e682605609e4005bf422a5d5e native
	iio-fm-radio 4c814e9e60d92cb2fac8c605695dc86999d4bc5e
	fru_tools 3b23074a1dc620a0335a27d0ece2849c4bc91ca9
	jesd-eye-scan-gtk 0fd8653fc081ebcc8b6189a96e91cea2275bb7e0
	colorimeter e25ba3a0ab63acc99b7d7c477da97f6c9eac9c6a native
	iio-oscilloscope 710df3258eaba61a8484a07dfc349e9a842f520a
	linux_image_ADI-scripts b379ef122782ce9ad9cbf8c01095b9e99579e553
	https://github.com/linux-usb-gadgets/gt.git 8ebbf3eb6fb77a53d6ace0eebf4f5debb779b576
"

# The repository and the build logs
cd "${KUIPER_DIR}"
APT_DIR=$(realpath -m "${ADI_LOCAL_REPO:-kuiper-build-temp/adi-local-repo}")
LOG_DIR=${APT_DIR}-logs
WORK=$(realpath -m "${KUIPER_BUILD_TEMP:-kuiper-build-temp}")/riscv64-packages
# The build environments of this work directory, by its uid and its path: the
# ones of another clone are left alone
ENV_TEMP=$(realpath -m "${KUIPER_BUILD_ENV_TEMP:-${TMPDIR:-/tmp}}")/kuiper-build-env-$(id -u)-$(printf '%s' "${WORK}" | sha256sum | cut -c 1-8)

# The Debian release and snapshot of the Kuiper config
eval "$(grep -E '^(DEBIAN_VERSION|DEBIAN_SNAPSHOT)=' config)"
if [ -n "${DEBIAN_SNAPSHOT}" ]; then
	MIRROR="https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}/"
else
	MIRROR="http://deb.debian.org/debian"
fi

# The subordinate ids of the user, which the user namespace of mmdebstrap maps
# its users to (its root to the first one)
subid() {
	[ ! -r "$1" ] || awk -F: -v user="$(id -un)" -v uid="$(id -u)" \
		'($1 == user || $1 == uid) && $3 > 0 { print $2 ":" $3; exit }' "$1"
}
SUBUID=$(subid /etc/subuid)
SUBGID=$(subid /etc/subgid)
[ -n "${SUBUID}" ] && [ -n "${SUBGID}" ] ||
	error "no subordinate ids of $(id -un) in /etc/subuid and /etc/subgid (mmdebstrap --mode=unshare needs them)"

# Removes the work directory and the build environments, with the files of the
# subordinate ids: in a user namespace where the user is root and the
# subordinate ids are mapped
remove_work() {
	local dir
	for dir in "${WORK}" "${ENV_TEMP}"; do
		[ ! -e "${dir}" ] || unshare --map-auto --map-root-user rm -rf "${dir}"
	done
}

# Whether the root of the user namespace of mmdebstrap can reach a directory
ns_root_reaches() {
	unshare --user --map-users="${SUBUID%:*},0,${SUBUID#*:}" \
		--map-groups="${SUBGID%:*},0,${SUBGID#*:}" --setuid 0 --setgid 0 \
		sh -c 'cd "$1"' sh "$1" 2> /dev/null
}

remove_work
trap remove_work EXIT
mkdir -p "$(dirname "${ENV_TEMP}")"
mkdir -m 755 "${ENV_TEMP}"
if ! ns_root_reaches "${ENV_TEMP}"; then
	# The first directory of the path that it cannot pass
	blocked=
	IFS=/ read -r -a parts <<< "${ENV_TEMP#/}"
	for part in "${parts[@]}"; do
		blocked+=/${part}
		ns_root_reaches "${blocked}" || break
	done
	error "the root of the user namespace of mmdebstrap (subordinate uid ${SUBUID%:*} of $(id -un)) cannot reach the directory of the build environments, ${ENV_TEMP}: it cannot pass ${blocked}. It needs the search (x) permission there, e.g.
    setfacl -m u:${SUBUID%:*}:x ${blocked}    (setfacl: the acl package; or: chmod o+x ${blocked})
or KUIPER_BUILD_ENV_TEMP in a directory that it can reach (default: TMPDIR, or /tmp)"
fi
mkdir -p "${WORK}/src" "${WORK}/logs" "${APT_DIR}" "${LOG_DIR}"
touch "${WORK}/packages.cross" "${WORK}/packages.native"

# The sources at their commits, and their versions as the ADI CI sets them:
# the highest version tag (packaging/VERSION, or adi-packages/<repository>/VERSION,
# when there is one) + the commit. <repository> is an ADI repository name or
# the URL of another repository.
echo "${ADI_PACKAGES}" | while read -r url commit mode; do
	[ -n "${url}" ] || continue
	[[ "${url}" == *://* ]] || url=${ADI_GITHUB}/${url}.git
	repo=$(basename "${url}" .git)
	[ $# -eq 0 ] || [[ " $* " == *" ${repo} "* ]] || continue
	src=${WORK}/src/${repo}
	git init -q "${src}"
	git -C "${src}" fetch -q --depth 1 "${url}" "${commit}"
	git -C "${src}" -c advice.detachedHead=false checkout -q FETCH_HEAD
	[ "$(git -C "${src}" rev-parse HEAD)" = "${commit}" ] || error "${repo} is not at ${commit}"
	if [ -f "${HERE}/adi-packages/${repo}/VERSION" ]; then
		version=$(tr -d '[:space:]' < "${HERE}/adi-packages/${repo}/VERSION")
	elif [ -f "${src}/packaging/VERSION" ]; then
		version=$(tr -d '[:space:]' < "${src}/packaging/VERSION")
	else
		version=$(git ls-remote --tags "${url}" | sed 's#.*refs/tags/##' |
			grep -E '^v?[0-9]+(\.[0-9]+)+$' | sort -V | tail -1 || true)
		version=${version#v}
		version=${version:-0.0.1}
	fi
	version=${version}+${commit:0:7}
	if ls "${APT_DIR}"/*_"${version}"-1_*.deb > /dev/null 2>&1; then
		echo "${repo} ${version}: in ${APT_DIR}"
		continue
	fi
	echo "${repo} ${version}: ${mode:-cross}"
	echo "${repo} ${version}" >> "${WORK}/packages.${mode:-cross}"
done

cp -r "${HERE}/adi-packages" "${WORK}/pkgs"

# build_env <architectures> <packages> <packages to install>
# (python3-pip: some packaging installs the Python bindings with pip, as on
# the ADI CI runners and containers, where it is installed;
# python3-setuptools: the setup.py of some Python bindings, e.g. libm2k,
# imports distutils, which Python has not had since 3.12: setuptools stands
# in for it, and the packaging does not depend on it)
# The certificates the build host trusts, also in the build environments:
# behind a TLS-inspecting proxy (its certificate in the trust store of the
# host), the downloads of apt, pip and git in the build environment would
# fail with the certificates of Debian only
HOST_CA=/etc/ssl/certs/ca-certificates.crt
[ -f "${HOST_CA}" ] || error "no ${HOST_CA} (ca-certificates)"

build_env() {
	rm -rf "${WORK}/apt"
	cp -r "${APT_DIR}" "${WORK}/apt"
	cp "$2" "${WORK}/packages"
	cp "${HOST_CA}" "${WORK}/host-ca.crt"
	TMPDIR="${ENV_TEMP}" mmdebstrap \
		--mode=unshare \
		--variant=buildd \
		--architectures="$1" \
		--components="main" \
		--include="$3,devscripts,debhelper,dpkg-dev,equivs,rsync,gettext-base,ca-certificates,python3-pip,python3-setuptools" \
		--keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
		--aptopt='Acquire::Check-Valid-Until "false"' \
		--customize-hook='mkdir -p "$1/work"' \
		--customize-hook="copy-in ${WORK}/src ${WORK}/pkgs ${WORK}/apt ${WORK}/logs ${WORK}/packages /work" \
		--customize-hook="copy-in ${WORK}/host-ca.crt /work" \
		--customize-hook='echo "Acquire::https::CaInfo \"/work/host-ca.crt\";" > "$1/etc/apt/apt.conf.d/99host-ca"' \
		--customize-hook='chroot "$1" env SSL_CERT_FILE=/work/host-ca.crt PIP_CERT=/work/host-ca.crt bash /work/pkgs/build-pkgs.sh riscv64' \
		--customize-hook="sync-out /work/apt ${APT_DIR}" \
		--customize-hook="sync-out /work/logs ${WORK}/logs" \
		--format=null \
		"${DEBIAN_VERSION}" /dev/null "${MIRROR}"
}

[ ! -s "${WORK}/packages.cross" ] ||
	build_env amd64,riscv64 "${WORK}/packages.cross" crossbuild-essential-riscv64,libc6-dev:riscv64
[ ! -s "${WORK}/packages.native" ] ||
	build_env riscv64 "${WORK}/packages.native" build-essential

cp "${WORK}"/logs/* "${LOG_DIR}/" 2> /dev/null || true
[ ! -f "${WORK}/logs/status" ] || cat "${WORK}/logs/status"
! grep -qs FAILED "${WORK}/logs/status" || error "some packages failed, see ${LOG_DIR}"
echo "Packages: ${APT_DIR}"
