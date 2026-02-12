ARG BASE_IMAGE=debian:trixie
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        parted moreutils e2fsprogs\
        coreutils qemu-user-static debootstrap zip dosfstools \
        rsync grep xxd kmod bc udev jq \
        build-essential gcc-arm-linux-gnueabihf \
        u-boot-tools gcc-aarch64-linux-gnu gnupg \
        binfmt-support ca-certificates qemu-utils fdisk \
    && rm -rf /var/lib/apt/lists/*
    
COPY . .

VOLUME ["kuiper-volume"]

