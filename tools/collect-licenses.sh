#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# Collects the licenses of the sources that a package is built from, for the
# packages that the tools build from outside sources (not the ADI packages,
# which have the copyright of their own packaging):
# - copies the license files of each source into <doc dir>/licenses/<source>/,
#   as they are in the source;
# - reads the license of each source from the SPDX-License-Identifier line
#   of its license files, or else from a COPYING.<license> or
#   LICENSE.<license> file name;
# - writes the Debian copyright file of the package, <doc dir>/copyright,
#   which 08.export-stage/03.generate-license lists in the license of the
#   image.
# The licenses follow the sources: nothing about them is written here.
#
# Usage: tools/collect-licenses.sh -p <package> -o <doc dir> <list>
#   <doc dir>  the documentation directory of the package, e.g.
#              <package root>/usr/share/doc/<package>
#   <list>     one source per line, the fields separated by |:
#              <name>|<source dir>|<URL>|<commit>|<files>|<license files>
#     <files>          the paths (globs) in the package that come from the
#                      source, as the Files field of the copyright format;
#                      the sources with the same files are one paragraph
#                      (e.g. "License: GPL-2.0 and MIT")
#     <license files>  the license files of the source, relative to its
#                      directory, separated by spaces

set -euo pipefail

error() { echo "ERROR: $*" >&2; exit 1; }
usage() { sed -n '/^# Usage/,/^#                      directory/p' "$0"; exit 2; }

package=
doc_dir=
while getopts "p:o:h" opt; do
	case $opt in
		p) package=$OPTARG ;;
		o) doc_dir=$OPTARG ;;
		*) usage ;;
	esac
done
shift $((OPTIND - 1))
[ -n "${package}" ] && [ -n "${doc_dir}" ] && [ $# -eq 1 ] || usage
list=$1
[ -f "${list}" ] || error "no ${list}"

# The license of a source, from its license files
license_of() {
	local dir=$1 file id
	shift
	for file in "$@"; do
		id=$(sed -n 's/.*SPDX-License-Identifier:[[:space:]]*//p' "${dir}/${file}" | head -n 1 |
			sed -e 's/[[:space:]]*\*\/[[:space:]]*$//' -e 's/[[:space:]]*$//')
		[ -z "${id}" ] || { echo "${id}"; return; }
	done
	for file in "$@"; do
		case $(basename "${file}") in
			COPYING.*|LICENSE.*)
				id=${file##*.}
				case ${id} in md|txt|rst) ;; *) echo "${id}"; return ;; esac
				;;
		esac
	done
}

mkdir -p "${doc_dir}/licenses"
names=() urls=() commits=() files=() licenses=() license_paths=()
while IFS='|' read -r name dir url commit pkg_files license_files; do
	[ -n "${name}" ] || continue
	[ -d "${dir}" ] || error "${name}: no source directory ${dir}"
	read -r -a lfiles <<< "${license_files}"
	[ ${#lfiles[@]} -gt 0 ] || error "${name}: no license files given"
	for file in "${lfiles[@]}"; do
		[ -f "${dir}/${file}" ] || error "${name}: no license file ${file} in ${dir}"
		mkdir -p "${doc_dir}/licenses/${name}/$(dirname "${file}")"
		cp "${dir}/${file}" "${doc_dir}/licenses/${name}/${file}"
	done
	license=$(license_of "${dir}" "${lfiles[@]}")
	[ -n "${license}" ] || error "${name}: cannot tell the license from ${license_files}"
	names+=("${name}") urls+=("${url}") commits+=("${commit:--}") files+=("${pkg_files}")
	licenses+=("${license}") license_paths+=("${name}/${lfiles[0]}")
done < "${list}"
[ ${#names[@]} -gt 0 ] || error "no sources in ${list}"

doc=/usr/share/doc/${package}
{
	echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
	echo "Upstream-Name: ${package}"
	echo "Source: ${urls[0]}"
	for ((i = 1; i < ${#urls[@]}; i++)); do
		[[ " ${urls[*]:0:i} " == *" ${urls[i]} "* ]] || echo " ${urls[i]}"
	done
	echo "Comment: The license files of each source, as in the source, are in"
	echo " ${doc}/licenses/<source>/. The sources:"
	for ((i = 0; i < ${#names[@]}; i++)); do
		echo " ${names[i]}: ${urls[i]} ${commits[i]}"
	done

	# One paragraph per set of files, with the licenses of its sources
	done_files=()
	for ((i = 0; i < ${#names[@]}; i++)); do
		[[ " ${done_files[*]} " == *" |${files[i]}| "* ]] && continue
		done_files+=("|${files[i]}|")
		srcs=() lics=()
		for ((j = i; j < ${#names[@]}; j++)); do
			[ "${files[j]}" = "${files[i]}" ] || continue
			srcs+=("${names[j]}")
			[[ " ${lics[*]} " == *" ${licenses[j]} "* ]] || lics+=("${licenses[j]}")
		done
		echo
		echo "Files: ${files[i]}"
		src_list=${srcs[0]}
		for ((k = 1; k < ${#srcs[@]}; k++)); do src_list+=", ${srcs[k]}"; done
		echo "Copyright: The authors of ${src_list}, see ${doc}/licenses/"
		lic=${lics[0]}
		for ((k = 1; k < ${#lics[@]}; k++)); do lic+=" and ${lics[k]}"; done
		echo "License: ${lic}"
	done

	# One paragraph per license, pointing at its text
	done_lics=()
	for ((i = 0; i < ${#names[@]}; i++)); do
		[[ " ${done_lics[*]} " == *" |${licenses[i]}| "* ]] && continue
		done_lics+=("|${licenses[i]}|")
		echo
		echo "License: ${licenses[i]}"
		echo " The license files, with the full text, are in:"
		for ((j = i; j < ${#names[@]}; j++)); do
			if [ "${licenses[j]}" = "${licenses[i]}" ]; then
				echo " ${doc}/licenses/${names[j]}/"
			fi
		done
	done
} > "${doc_dir}/copyright"

for ((i = 0; i < ${#names[@]}; i++)); do
	echo "${names[i]}: ${licenses[i]} (${license_paths[i]})"
done
