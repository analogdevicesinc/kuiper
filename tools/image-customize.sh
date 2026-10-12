#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>
#
# image-customize.sh - Open a pre-built Kuiper .img with libguestfs, apply
# changes to its boot and rootfs partitions, then cleanup
#
# This is a POST-BUILD maintenance tool: run it against a finished image, e.g.
# one downloaded from CI or a release. It edits the image
# in place, partition sizes, PARTUUIDs, permissions, symlinks and xattrs are
# preserved. Runs on an x86_64 host.
#
# Usage:
#   ./image-customize.sh <image.img> <script>
#   GROW=5G ./image-customize.sh <image.img> <script>
#
#   <script>  A host-side script run inside the target rootfs. It is copied in,
#             executed, then removed
#
#   GROW=<size>  Optional env var. Enlarge the image and stretch the rootfs
#                partition by <size> (e.g. GROW=5G) before customizing, so large
#                installs fit. Unset = no resize
#
# Prerequisites:
#   sudo apt install libguestfs-tools qemu-user-static linux-image-generic

# Pretty print
log()  { echo "$*"; }
step() { echo "$*"; }
err()  { echo "ERROR: $*" >&2; }

# Print help / how to use the tool.
usage() {
	cat <<EOF
image-customize.sh - customize a pre-built Kuiper .img in place.

Usage:
  $0 <image.img> <script>
  GROW=<size> $0 <image.img> <script>

Arguments:
  <image.img>   Kuiper image to modify (edited in place).
  <script>      Host-side script run inside the image's rootfs as root (/ = rootfs).
                Copied in, executed, then removed.
  GROW=<size>   Enlarge the image + rootfs before customizing (e.g. GROW=5G) so
                large installs fit. Kept change (bigger image). Unset = no resize.

Requirements:
  libguestfs-tools and qemu-user-static installed:
    sudo apt install libguestfs-tools qemu-user-static
EOF
}

# libguestfs session and temporary directory inside the image, for the cleanup
GUESTFISH_PID=""
STAGE=""
TMP_FILE=""

# Send a command to the libguestfs session
g() {
	guestfish --remote="${GUESTFISH_PID}" -- "$@"
}

# Remove the copied hook and qemu, then close the image. Runs on
# every exit (success, error, or interrupt) as the EXIT trap.
cleanup() {
	rc=$?
	[ -z "${STAGE}" ] || g rm-rf "${STAGE}" || true
	[ -z "${GUESTFISH_PID}" ] || g exit || true
	rm -f "${TMP_FILE}"
	exit "${rc}"
}

# argument parsing
case "${1:-}" in
	-h|--help|help) usage; exit 0 ;;
esac

IMG_FILE="${1:-}"
EXTRA_SCRIPT="${2:-${EXTRA_SCRIPT:-}}"

if [ -z "${IMG_FILE}" ] || [ -z "${EXTRA_SCRIPT}" ]; then
	usage >&2
	exit 1
fi
if [ ! -f "${IMG_FILE}" ]; then
	err "Image not found: ${IMG_FILE}"
	exit 1
fi
if [ ! -f "${EXTRA_SCRIPT}" ]; then
	err "Script not found: ${EXTRA_SCRIPT}"
	exit 1
fi

trap cleanup EXIT INT TERM
TMP_FILE="$(mktemp)"

# optionally grow the image so large installs fit
if [ -n "${GROW:-}" ]; then
	step "Growing image by ${GROW}"
	truncate -s "+${GROW}" "${IMG_FILE}"
fi

# Start libguestfs
step "Opening ${IMG_FILE}"
export LIBGUESTFS_BACKEND=direct
eval "$(guestfish --listen --network)"
g add-drive "${IMG_FILE}" format:raw
g run

# Grow the ext4 filesystem
if [ -n "${GROW:-}" ]; then
	step "Resizing the rootfs partition and filesystem"
	g part-resize /dev/sda 2 "$(($(g blockdev-getsz /dev/sda) - 1))"
	g e2fsck /dev/sda2 correct:true
	g resize2fs /dev/sda2
fi

# Mount rootfs and boot
g mount /dev/sda2 /
g mount /dev/sda1 /boot

# Detect the image architecture
KUIPER_ARCH="$(g cat /etc/kuiper-release | sed -n 's/^KUIPER_ARCH="\?\([^"]*\)"\?$/\1/p')"
case "${KUIPER_ARCH}" in
	armhf) QEMU=qemu-arm
	       MAGIC='\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00' ;;
	arm64) QEMU=qemu-aarch64
	       MAGIC='\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00' ;;
	*)     err "Unsupported KUIPER_ARCH: ${KUIPER_ARCH:-unknown}"; exit 1 ;;
esac
QEMU="$(command -v "${QEMU}-static" || command -v "${QEMU}")"
step "Image architecture: ${KUIPER_ARCH} (using ${QEMU})"

# Copy the static qemu and hook into a temporary directory in the rootfs
STAGE="$(g mkdtemp /tmp/kuiper-customize.XXXXXX)"
g upload "${QEMU}" "${STAGE}/qemu"
g upload "${EXTRA_SCRIPT}" "${STAGE}/hook"
g chmod 0755 "${STAGE}/hook"

# Register qemu with binfmt_misc inside the libguestfs VM,
# the F flag opens qemu at registration
MASK='\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'
printf '%s\n' "install -m 0755 /sysroot${STAGE}/qemu /tmp/qemu" \
	"mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc" \
	"printf '%s' ':kuiper:M::${MAGIC}:${MASK}:/tmp/qemu:F' > /proc/sys/fs/binfmt_misc/register" \
	> "${TMP_FILE}"
g upload "${TMP_FILE}" "${STAGE}/binfmt"
g debug sh "sh -e /sysroot${STAGE}/binfmt"

# libguestfs provides /dev, /proc, /sys and DNS for the chroot.
step "Running ${EXTRA_SCRIPT} inside the target rootfs"
g sh "cd / && LC_ALL=C ${STAGE}/hook > ${STAGE}/log 2>&1; echo \$? > ${STAGE}/rc"
g download "${STAGE}/log" /dev/stdout
RC="$(g cat "${STAGE}/rc")"
if [ "${RC}" -ne 0 ]; then
	err "${EXTRA_SCRIPT} failed with status ${RC}"
	exit "${RC}"
fi

log "Changes written to ${IMG_FILE}"
# cleanup() (the EXIT trap) now removes the copied hook and qemu, then closes
# the image
