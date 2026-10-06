#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>
#
# image-customize.sh - Loop-mount a pre-built Kuiper .img, apply changes to its
# boot and rootfs partitions, then cleanup, unmount and detach
#
# This is a POST-BUILD maintenance tool: run it against a finished image, e.g.
# one downloaded from CI or a release. It edits the image
# in place via a loop device - no filesystem is rebuilt, so partition sizes,
# PARTUUIDs, permissions, symlinks and xattrs are all preserved.
# It supports Ubuntu and Debian on an x86_64 host
#
# Usage:
#   sudo ./image-customize.sh <image.img> <script>
#   sudo GROW=5G ./image-customize.sh <image.img> <script>
#
#   <script>  A host-side script run inside the target rootfs. It is copied in,
#             executed, then removed
#
#   GROW=<size>  Optional env var. Enlarge the image and stretch the rootfs
#                partition by <size> (e.g. GROW=5G) before customizing, so large
#                installs fit. Unset = no resize
#
# Prerequisites:
#   sudo apt install qemu-user-static binfmt-support

# Pretty print
log()  { echo "$*"; }
step() { echo "$*"; }
err()  { echo "ERROR: $*" >&2; }

# Print help / how to use the tool.
usage() {
	cat <<EOF
image-customize.sh - customize a pre-built Kuiper .img in place.

Usage:
  sudo $0 <image.img> <script>
  sudo GROW=<size> $0 <image.img> <script>

Arguments:
  <image.img>   Kuiper image to modify (edited in place via a loop device).
  <script>      Host-side script run inside the image's rootfs as root (/ = rootfs).
                Copied in, executed, then removed.
  GROW=<size>   Enlarge the image + rootfs before customizing (e.g. GROW=5G) so
                large installs fit. Kept change (bigger image). Unset = no resize.

Requirements:
  Run as root, with qemu-user-static + binfmt-support installed:
    sudo apt install qemu-user-static binfmt-support
EOF
}

# Variables for the cleanup
LOOP_DEV=""    # loop device attached
MOUNT_DIR=""   # location of the mounted rootfs

# Run a command inside the target rootfs. Wraps chroot so every call goes through
# one place; LC_ALL=C silences the host-locale warnings
in_target() {
	chroot "${MOUNT_DIR}" env LC_ALL=C "$@"
}

# Run an external customization script inside the target rootfs
# It is copied in, executed, then removed
run_hook() {
	# Save the image's resolver and drop in a working one so apt-based hooks can
	# reach the network;
	mv "${MOUNT_DIR}/etc/resolv.conf" "${MOUNT_DIR}/etc/resolv.conf.orig"
	echo 'nameserver 8.8.8.8' > "${MOUNT_DIR}/etc/resolv.conf"

	# Copy the hook into the rootfs and run it there
	install -m 0755 "${EXTRA_SCRIPT}" "${MOUNT_DIR}/tmp/$(basename "${EXTRA_SCRIPT}")"
	in_target "/tmp/$(basename "${EXTRA_SCRIPT}")"
}

# Undo everything added for networking and chroot. Runs on
# every exit (success, error, or interrupt) as the EXIT trap.
cleanup() {
	rc=$?
	rm -f "${MOUNT_DIR}/usr/bin/qemu-arm-static" "${MOUNT_DIR}/usr/bin/qemu-aarch64-static" 2>/dev/null || true
	rm -f "${MOUNT_DIR}/tmp/$(basename "${EXTRA_SCRIPT}")" 2>/dev/null || true
	rm -f "${MOUNT_DIR}/etc/resolv.conf" 2>/dev/null || true
	mv "${MOUNT_DIR}/etc/resolv.conf.orig" "${MOUNT_DIR}/etc/resolv.conf" 2>/dev/null || true
	sync 2>/dev/null || true
	umount -R "${MOUNT_DIR}" 2>/dev/null || true
	rmdir "${MOUNT_DIR}" 2>/dev/null || true
	losetup -d "${LOOP_DEV}" 2>/dev/null || true
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
if [ "$(id -u)" -ne 0 ]; then
	err "This script needs root. Please re-run with sudo."
	exit 1
fi

trap cleanup EXIT INT TERM

# optionally grow the image so large installs fit
if [ -n "${GROW:-}" ]; then
	step "Growing image by ${GROW} and extending the rootfs partition"
	truncate -s "+${GROW}" "${IMG_FILE}"
	parted -s "${IMG_FILE}" resizepart 2 100%
fi

# Attach the image as a partitioned loop device
step "Attaching ${IMG_FILE} as a loop device"
LOOP_DEV="$(losetup --show -f -P "${IMG_FILE}")"
log "Attached at ${LOOP_DEV}"

BOOT_PART="${LOOP_DEV}p1"
ROOT_PART="${LOOP_DEV}p2"

# Give udev a moment to create the partition nodes (the usual case on a desktop).
for _ in $(seq 1 10); do
	[ -b "${BOOT_PART}" ] && [ -b "${ROOT_PART}" ] && break
	sleep 0.5
done

if [ ! -b "${ROOT_PART}" ]; then
	err "Partition device ${ROOT_PART} never appeared"
	exit 1   # cleanup() detaches the loop device
fi

# Grow the ext4 filesystem
if [ -n "${GROW:-}" ]; then
	step "Resizing the rootfs filesystem"
	e2fsck -f -y "${ROOT_PART}" || true
	resize2fs "${ROOT_PART}"
fi

# Mount rootfs and boot
MOUNT_DIR="$(mktemp -d /tmp/kuiper-img.XXXXXX)"
step "Mounting rootfs (${ROOT_PART}) at ${MOUNT_DIR}"
mount "${ROOT_PART}" "${MOUNT_DIR}"
step "Mounting boot  (${BOOT_PART}) at ${MOUNT_DIR}/boot"
mount "${BOOT_PART}" "${MOUNT_DIR}/boot"

# Detect the image architecture
if [ ! -f "${MOUNT_DIR}/etc/kuiper-release" ]; then
	err "No /etc/kuiper-release in image - cannot determine architecture"
	exit 1
fi
. "${MOUNT_DIR}/etc/kuiper-release"
case "${KUIPER_ARCH:-}" in
	armhf) QEMU=qemu-arm-static ;;
	arm64) QEMU=qemu-aarch64-static ;;
	*)     err "Unsupported KUIPER_ARCH: ${KUIPER_ARCH:-unknown}"; exit 1 ;;
esac
step "Image architecture: ${KUIPER_ARCH} (using ${QEMU})"
cp "/usr/bin/${QEMU}" "${MOUNT_DIR}/usr/bin/${QEMU}"
mount -t proc   proc   "${MOUNT_DIR}/proc"
mount -t sysfs  sys    "${MOUNT_DIR}/sys"
mount --bind    /dev   "${MOUNT_DIR}/dev"
mount -t devpts devpts "${MOUNT_DIR}/dev/pts"

step "Running ${EXTRA_SCRIPT} inside the target rootfs"
run_hook

log "Changes written to ${IMG_FILE}"
step "Restoring changes, unmounting and detaching"
# cleanup() (the EXIT trap) now restores resolv.conf, removes the copied hook and
# qemu, then unmounts and detaches
