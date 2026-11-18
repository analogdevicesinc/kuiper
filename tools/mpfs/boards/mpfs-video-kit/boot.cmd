# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# Boot script of the Kuiper image on the PolarFire SoC Video Kit (boot.scr):
# the kernel Image and the devicetree of the project (mss.dtb) are separate
# files of the boot partition, as on the ZynqMP carriers; the bootargs come
# from the U-Boot environment (uboot.env).

load mmc 0:${distro_bootpart} ${kernel_addr_r} Image
load mmc 0:${distro_bootpart} ${fdt_addr_r} mss.dtb
fdt addr ${fdt_addr_r}
run design_overlays
booti ${kernel_addr_r} - ${fdt_addr_r}
