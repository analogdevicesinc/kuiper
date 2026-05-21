#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

mkdir -p /home/analog/adi-tools

# Install Debian packages for general exercises
apt install -y picocom

# Install Visual Studio Code
wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-arm64"
echo "n" | dpkg -i vscode.deb
rm vscode.deb

echo 'alias code="code --use-inmemory-secretstorage"' >> /etc/bash.bashrc

# Install Docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

apt-get install -y python3 python3-pip python3-setuptools python3-venv
yes | pip install paramiko matplotlib pandas-stubs --break-system-packages

cp stages/07.extra-tweaks/01.extra-scripts/files/kernel_2712.img /boot/


apt-get install -y fakeroot libncurses5-dev libssl-dev ccache dfu-util u-boot-tools device-tree-compiler libssl-dev mtools cpio zip unzip rsync file bc gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf dfu-util u-boot-tools mpc libmpc-dev
cd /home/analog/adi-tools
git clone --recursive --shallow-submodules https://github.com/analogdevicesinc/plutosdr-fw.git
sed -i 's/arm-linux-gnueabihf-/arm-none-linux-gnueabihf-/g' plutosdr-fw/Makefile

sed -i 's/analog/training-SDP-RTP-pi5/g' /etc/hostname
sed -i 's/analog/training-SDP-RTP-pi5/g' /etc/hosts
