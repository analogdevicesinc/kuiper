#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Alisa-Dariana Roman <alisa.roman@analog.com>

# Stamp the image identity so a Kuiper image is reliably recognizable both
# offline and on the running device. Build environment variables are rendered
# into several artifacts:
#
#   - boot/kuiper-release.json : machine-readable manifest on the FAT32 BOOT
#     partition.
#   - /etc/kuiper-release      : the same facts in os-release (shell) format for
#     on-device tooling (`. /etc/kuiper-release`).
#   - /etc/kuiper-packages     : the installed package versions (dpkg).

SCHEMA_VERSION=1

mkdir -p "${BUILD_DIR}/boot"

# 1) On-device identity file.
cat > "${BUILD_DIR}/etc/kuiper-release" << EOF
KUIPER_NAME="ADI Kuiper Linux"
KUIPER_SCHEMA_VERSION=${SCHEMA_VERSION}
KUIPER_VERSION="${KUIPER_VERSION}"
KUIPER_BUILD_DATE="${BUILD_DATE}"
KUIPER_COMMIT="${KUIPER_COMMIT}"
KUIPER_ARCH="${TARGET_ARCHITECTURE}"
KUIPER_VARIANT="${KUIPER_VARIANT}"
KUIPER_DEBIAN_VERSION="${DEBIAN_VERSION}"
KUIPER_DEBIAN_SNAPSHOT="${DEBIAN_SNAPSHOT}"
EOF

# 2) Component provenance: the installed package versions.
chroot "${BUILD_DIR}" dpkg-query -W -f '${Package} ${Version}\n' 2>/dev/null \
	| sort > "${BUILD_DIR}/etc/kuiper-packages"

# 3) Machine-readable manifest on the BOOT partition.
jq -n \
	--argjson schema_version "${SCHEMA_VERSION}" \
	--arg version "${KUIPER_VERSION}" \
	--arg build_date "${BUILD_DATE}" \
	--arg commit "${KUIPER_COMMIT}" \
	--arg arch "${TARGET_ARCHITECTURE}" \
	--arg variant "${KUIPER_VARIANT}" \
	--arg debian_version "${DEBIAN_VERSION}" \
	--arg debian_snapshot "${DEBIAN_SNAPSHOT}" \
	'{$schema_version, $version, $build_date, $commit, $arch, $variant, $debian_version, $debian_snapshot}' \
	> "${BUILD_DIR}/boot/kuiper-release.json"

echo "Image identity: Kuiper ${KUIPER_VERSION} (${TARGET_ARCHITECTURE}/${KUIPER_VARIANT}) built ${BUILD_DATE}"
