#/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Andreea Andrisan <andreea.andrisan@analog.com>

# This script it takes as arguments the config file that we want to modify and a list of configurations with the new value
# Ex: ./modify_config.sh ./config "TARGET_ARCHITECTURE=arm64 BRANCH_RPI_BOOT_FILES=rpi-5.15.y"
config_file=$1
arguments=$2
if [ ! -f $config_file ]; then
	echo $config_file: File not found!
	exit 1
fi

echo "Build arguments: "
for argument in $arguments
do
    echo $argument
    # split the argument in order to search the configuration in the config file
    IFS='=' read -ra config <<< "$argument"
    value=$(grep -E -o -n ^${config[0]}= $config_file)
    if [[ $value != "" ]]; then
        # extract line number from the value returned by the grep command and replace it with the new argument
        IFS=':' read -ra line_value <<< "$value"
        sed -i "${line_value[0]}s/.*/$argument/" $config_file
    else
        echo "This configuration ${config[0]} was not found in the config file"
    fi
done
