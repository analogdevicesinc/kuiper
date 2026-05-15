#!/bin/bash -e
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

mkdir -p /home/analog


sed -i 's/analog/training-SDP-RTP-jupiter/g' /etc/hostname
sed -i 's/analog/training-SDP-RTP-jupiter/g' /etc/hosts
