#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# Runs in a build environment of build-adi-packages.sh: builds the packages of
# /work/packages (<repository> <version>) for the given architecture, in
# order, from /work/src/<repository>, with the steps of the ADI
# deb-generator-action (build-deb.sh): cross-compiled when the environment is
# of another architecture (dpkg-buildpackage -a), natively otherwise. A
# adi-packages/<repository>.sh, when there is one, adapts the packaging before the
# build (sourced in the build tree). Each package goes into the local apt
# repository /work/apt, so the next ones can depend on it. The result of each
# one is added to /work/logs/status, its build log is
# /work/logs/<repository>.log.
#
# Usage: build-pkgs.sh <architecture>

set -uo pipefail

HOST_ARCH=$1
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)"

cross=()
[ "$(dpkg --print-architecture)" = "${HOST_ARCH}" ] || cross=(-a "${HOST_ARCH}")

update_repo() {
	(cd /work/apt && dpkg-scanpackages --multiversion . > Packages 2> /dev/null && gzip -kf Packages)
	apt-get update -qq
}
echo "deb [trusted=yes] file:/work/apt ./" > /etc/apt/sources.list.d/work-apt.list
update_repo

build() {
	local repo=$1 version=$2
	local src=/work/src/${repo} control=packaging/debian
	local app build_root

	cd "${src}"
	# the older layout, debian/ at the top; or, for a repository without a
	# packaging, ours: pkgs/<repository>/debian
	[ -d "${control}" ] || control=debian
	if [ -d "${HERE}/${repo}/debian" ]; then
		control=packaging/debian
		mkdir -p packaging
		cp -r "${HERE}/${repo}/debian" "${control}"
	fi
	# a control file with ${PACKAGE} (envsubst templates): the package name
	# is the PACKAGE default of debian/rules
	if [ -f "${control}/control.template" ]; then
		export PACKAGE=$(sed -n 's/^PACKAGE ?= *//p' "${control}/rules")
		export VERSION=${version} DATE=$(date -R) CHANGELOG_ENTRY="Release ${version}"
		app=${PACKAGE}
	else
		app=$(grep -m1 '^Source:' "${control}/control" | awk '{print $2}')
	fi
	echo "==> ${repo}: ${app} ${version} (${HOST_ARCH}${cross:+, cross})"

	build_root=$(mktemp -d)
	rsync -a --exclude=.git --exclude="/${control}" ./ "${build_root}/${app}/"
	cp -r "${control}" "${build_root}/${app}/debian"
	cd "${build_root}/${app}"

	for t in debian/*.template; do
		[ -e "${t}" ] && envsubst < "${t}" > "${t%.template}" && rm "${t}"
	done
	sed -i "s|@VERSION@|${version}-1|" debian/changelog
	sed -i "s|@DATE@|$(date -R)|" debian/changelog
	sed -i "s|@ARCHITECTURE@|${HOST_ARCH}|" debian/control

	if [ -f "${HERE}/${repo}.sh" ]; then
		echo "==> ${repo}: pkgs/${repo}.sh"
		source "${HERE}/${repo}.sh" || return 1
	fi

	# (mk-build-deps of the ADI script: apt-get build-dep does the same,
	# also for another host architecture)
	apt-get -y --no-install-recommends "${cross[@]}" build-dep ./ || return 1
	dpkg-buildpackage "${cross[@]}" -b -us -uc || return 1

	cp ../*.deb /work/apt/
	update_repo
}

while read -r repo version; do
	start=$(date +%s)
	if build "${repo}" "${version}" > "/work/logs/${repo}.log" 2>&1; then
		result=OK
	else
		result=FAILED
	fi
	echo "${repo} ${version} ${HOST_ARCH}${cross:+ cross} ${result} $(( $(date +%s) - start ))s" | tee -a /work/logs/status
done < /work/packages
