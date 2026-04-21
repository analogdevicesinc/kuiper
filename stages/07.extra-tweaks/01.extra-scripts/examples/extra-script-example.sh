#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

############## GUIDELINES ##############

# - This script is run inside 'chroot'. 
# 	* it works as if Kuiper is running on a system with a few limitations
# 	* check 'chroot' documentation for more informations
# - This script is run as root, there is no need to use 'sudo' command.
# - Current directory is '/' (root) of the Kuiper rootfs.
# - If a file needs to be copied, it should be placed inside 'kuiper'.
# - If a variable from the configuration file is needed, source the config file to access its value.
# - At this stage the Kuiper image is not yet partitioned. In order to modify what will be in the boot partition access /boot folder.
# - This script will not be in the resulted image. If this is necessary it should be copied manually.

############## EXAMPLES ##############

# Source the config file to access configuration variables inside script
# source config

# Package installation
# apt install -y <package>

# Package installation without recommended packages (useful when Kuiper image size should be small)
# apt install -y <package> --no-install-recommends

# Copy a file placed in the examples folder to the current directory
# cp stages/07.extra-scripts/examples/<file-to-be-copied> .

# Enable a service 
# systemctl enable <service>.service
