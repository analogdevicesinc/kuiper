<!--
SPDX-License-Identifier: BSD-3-Clause
Copyright (c) 2026 Analog Devices, Inc.
-->

# Microchip PolarFire SoC tools

The tools that build the Kuiper image of the Microchip PolarFire SoC boards
(riscv64). The full description is in
[docs/polarfire-soc.rst](../../docs/polarfire-soc.rst).

| File | What it does |
|---|---|
| `build-image.sh` | Everything in one go: the kernel, the ADI packages (`../riscv64/build-adi-packages.sh`), the boot files, the settings of `mpfs.config` in `config`, and `sudo bash build-docker.sh` |
| `build-boot-files.sh` | The boot files of the boards (kernel, devicetrees, U-Boot payload, boot script, U-Boot environment, `kuiper.json`) as the `adi-mpfs-boot` package, into the local package repository |
| `mpfs.config` | The Kuiper settings of the PolarFire SoC images |
| `boards/<board>/board.conf` | A board: its names in `kuiper.json`, its projects and devicetrees, the `meta-mchp`, U-Boot and HSS settings |
| `boards/<board>/boot.cmd` | The boot script of the board (`boot.scr`) |

## Quick start

On an amd64 Debian or Ubuntu build host:

```sh
tools/mpfs/build-image.sh -i -c            # check the build host, install what is missing
tools/mpfs/build-image.sh -p fmcomms2      # the image, configured for fmcomms2 on mpfs_video_kit
```

The kernel comes from the `staging/main-mpfs` branch of
[ADI Linux](https://github.com/analogdevicesinc/linux) (`adi_mpfs_defconfig`);
the image is in `kuiper-volume`, as any Kuiper image.

| Option | Description |
|---|---|
| `-k <build>` | An existing ADI Linux build (`O=`) instead of fetching and building the kernel |
| `-n` | Without the kernel and the devicetrees |
| `-L <repository>` | The ADI Linux repository: a URL or a local clone (`LINUX_URL`) |
| `-B <branch>` | Its branch (`LINUX_BRANCH`, default `staging/main-mpfs`) |
| `-p <eval board>` | Configure the image for a project (`ADI_EVAL_BOARD`, `CARRIER=mpfs_video_kit`) |
| `-s` | Stop before the image (no `build-docker.sh`) |
| `-i` | Install what the build host is missing |
| `-c` | Only check the build host |

## What is built where

The build files are in the build temp directory, `kuiper-build-temp`
(`KUIPER_BUILD_TEMP`, relative to the `kuiper` folder, in `.gitignore`);
`kuiper-volume` has the outputs of the image build only, as on the other
architectures. Removing `kuiper-build-temp` cleans the build.

| Directory | Content |
|---|---|
| `kuiper-build-temp/linux`, `kuiper-build-temp/linux-build` | The kernel source (the last commit of the branch) and its build |
| `kuiper-build-temp/adi-local-repo` | The local package repository: the ADI packages for riscv64 and `adi-mpfs-boot` (`ADI_LOCAL_REPO`); the image build copies it into its container (`.dockerignore`), so it stays in the `kuiper` folder |
| `kuiper-build-temp/mpfs-boot-work` | The U-Boot, HSS and `meta-mchp` sources and builds of the boot files |
| `kuiper-volume/*.zip` | The image |
