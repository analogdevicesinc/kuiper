#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

source config

DEBIAN_VERSION=${DEBIAN_VERSION:-bookworm}
BASE_IMAGE="debian:${DEBIAN_VERSION}"
IMAGE_NAME="debian_${DEBIAN_VERSION}_rootfs"
CONTAINER_NAME=${CONTAINER_NAME:-"${IMAGE_NAME}_container"}
PRESERVE_CONTAINER=${PRESERVE_CONTAINER:-n}

cleanup() {
	docker rm -fv ${CONTAINER_NAME}
	exit 1
}

# Remove container if build was interrupted or cancelled
trap cleanup SIGINT SIGTERM

# Check if the script is run as root
if [ "$(id -u)" != "0" ] ; then
	echo "This script must be run as root"
	exit 1
fi

# Check if Debian version is supported
if [[ ! ${DEBIAN_VERSION} = bookworm && ! ${DEBIAN_VERSION} = bullseye && ! ${DEBIAN_VERSION} = trixie ]]; then
	echo "Unsupported Debian version ${DEBIAN_VERSION}"
	exit 1
fi

# Build docker image
docker build --build-arg BASE_IMAGE="${BASE_IMAGE}" -t ${IMAGE_NAME} .

# Run docker container
# -t: pseudo-TTY allowing interaction with container's shell
# --privileged: elevanted privileges required by the chroot command
# -v: mounts volumes allowing the container to access files on the host or work with kernel modules
# -e: sets environment variables
# Inside the container kuiper-stages.sh will run building the Kuiper image
docker run -t --privileged \
			-v /dev:/dev \
			-v /lib/modules:/lib/modules \
			-v ./kuiper-volume:/kuiper-volume \
			-e "DEBIAN_VERSION="${DEBIAN_VERSION}"" \
			--name ${CONTAINER_NAME} ${IMAGE_NAME} \
			/bin/bash -o pipefail -c "bash kuiper-stages.sh"

if [ $PRESERVE_CONTAINER = n ]; then
	# Remove image, container and corresponding volume
	docker rm -v ${CONTAINER_NAME}
fi

docker image rm -f ${IMAGE_NAME}

# Detach loops
LOOP_DEVICES=$(losetup --list | grep "$(basename "ADI-Kuiper-Linux.*.img")" | cut -f1 -d' ')
for LOOP_DEV in ${LOOP_DEVICES}; do
	losetup -d ${LOOP_DEV}
done


# Save info about adi-kuiper-gen repository in log file
echo -e "\nADI Kuiper Linux:" >> "kuiper-volume/ADI_repos_git_info.txt"
echo "Repo   : $(git remote get-url origin)" >> "kuiper-volume/ADI_repos_git_info.txt"
echo "Branch : $(git branch | cut -d' ' -f2)" >> "kuiper-volume/ADI_repos_git_info.txt"
echo -e "Git_sha: $(git rev-parse --short HEAD)\n\n" >> "kuiper-volume/ADI_repos_git_info.txt"
