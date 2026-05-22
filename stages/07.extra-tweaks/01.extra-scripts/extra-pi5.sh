#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

# Install Debian packages for general exercises
apt install -y picocom

# Install Visual Studio Code
wget -qO vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-arm64"
echo "n" | dpkg -i vscode.deb
rm vscode.deb

echo 'alias code="code --use-inmemory-secretstorage"' >> /etc/bash.bashrc

apt-get install -y python3 python3-pip python3-setuptools python3-venv
yes | pip install paramiko matplotlib pandas-stubs sshfs --break-system-packages

apt-get install -y fakeroot libncurses5-dev libssl-dev ccache dfu-util u-boot-tools device-tree-compiler libssl-dev mtools cpio zip unzip rsync file bc gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf dfu-util u-boot-tools mpc libmpc-dev
cd /home/analog/adi-tools
git clone --recursive --shallow-submodules https://github.com/analogdevicesinc/plutosdr-fw.git
sed -i 's/arm-linux-gnueabihf-/arm-none-linux-gnueabihf-/g' plutosdr-fw/Makefile

git clone --depth 1 https://github.com/analogdevicesinc/linux.git

install -m 600 "/stages/07.extra-tweaks/01.extra-scripts/files/SDP_SW training.nmconnection"	"/etc/NetworkManager/system-connections/"

cp /stages/07.extra-tweaks/01.extra-scripts/files/kernel_2712.img /boot/
cp -r /stages/07.extra-tweaks/01.extra-scripts/files/talise-tracker /home/analog/adi-tools/pyadi-iio/examples/

sed -i 's/analog/training-SDP-RTP-pi5/g' /etc/hostname
sed -i 's/analog/training-SDP-RTP-pi5/g' /etc/hosts
