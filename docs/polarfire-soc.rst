.. _polarfire-soc:

Microchip PolarFire SoC (riscv64)
=================================

.. description::

   Build Kuiper images for the Microchip PolarFire SoC boards (RISC-V,
   riscv64): the ADI packages, the boot files and the image

The Microchip PolarFire SoC (MPFS) has a RISC-V application processor, so its
Kuiper image is a ``riscv64`` one (an official Debian architecture since
trixie). The build is the Kuiper one, with:

- ``TARGET_ARCHITECTURE=riscv64``;
- ``CONFIG_ARCH_MPFS=y``: the PolarFire SoC boot files (the ``adi-mpfs-boot``
  package) and the PolarFire SoC image layout;
- ``ADI_LOCAL_REPO``: the ADI packages for ``riscv64`` from a local package
  repository, as the ADI package repository has ``amd64``, ``arm64`` and
  ``armhf`` packages only.

The first supported board is the PolarFire SoC Video Kit, with the
``projects/fmcomms2/mpfs_video_kit`` HDL project: AD-FMCOMMS2-EBZ,
AD-FMCOMMS3-EBZ and EVAL-AD-FMCOMMS4-EBZ.

----

Quick Build
-----------

On an ``amd64`` Debian or Ubuntu build host:

.. shell::

   $tools/mpfs/build-image.sh -i -c
   $tools/mpfs/build-image.sh

``tools/mpfs/build-image.sh`` does the steps below in one go: the kernel and
the devicetrees (the ``staging/main-mpfs`` branch of the ADI Linux
repository, fetched in ``kuiper-build-temp/linux`` and built with
``adi_mpfs_defconfig`` in ``kuiper-build-temp/linux-build``), the ADI
packages, the boot files, the settings of ``tools/mpfs/mpfs.config`` in
``config`` (as the Kuiper CI does, with ``ci/modify_config.sh``; ``git diff
config`` shows them) and ``sudo bash build-docker.sh``. The image is in
``kuiper-volume``, as any Kuiper image.

The build files are in the build temp directory, ``kuiper-build-temp``
(``KUIPER_BUILD_TEMP``, relative to the ``kuiper`` folder, in
``.gitignore``): the kernel, the local package repository, the work
directories and the logs of the tools. ``kuiper-volume`` has the outputs of
the image build only, as on the other architectures. Removing
``kuiper-build-temp`` cleans the build.
``tools/mpfs/README.md`` and ``tools/riscv64/README.md`` sum up the tools.

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Description
   * - ``-k <build>``
     - An existing ADI Linux build (``O=``) of the kernel ``Image`` and the
       devicetrees, instead of fetching and building the kernel:
       ``make O=<build> ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu-
       adi_mpfs_defconfig Image dtbs``
   * - ``-n``
     - Without the kernel and the devicetrees: the boot files of the boards
       only
   * - ``-L <repository>``
     - The ADI Linux repository to build the kernel from: a URL or a local
       clone (``LINUX_URL``, default
       ``https://github.com/analogdevicesinc/linux.git``)
   * - ``-B <branch>``
     - Its branch (``LINUX_BRANCH``, default ``staging/main-mpfs``); the last commit
       of the branch is fetched
   * - ``-p <eval board>``
     - Configure the image for a project at build time (``ADI_EVAL_BOARD``,
       ``CARRIER=mpfs_video_kit``), e.g. ``-p fmcomms2``; by default the
       image is not configured, as the Kuiper images
   * - ``-s``
     - Stop before the image: the kernel, the packages, the boot files and
       ``config`` only
   * - ``-i``
     - Install what the build host is missing (``sudo apt install``, the
       ``riscv64`` binfmt); without it, only what is missing is printed
   * - ``-c``
     - Only check the build host

----

Build Steps
-----------

ADI packages for riscv64
~~~~~~~~~~~~~~~~~~~~~~~~

.. shell::

   $tools/riscv64/build-adi-packages.sh

It builds the ADI packages that the ``05.adi-tools`` stages install into the
local package repository ``kuiper-build-temp/adi-local-repo`` (or
``ADI_LOCAL_REPO``), with the steps of the ADI CI (the
``deb-generator-action`` of ``analogdevicesinc/shared-actions``: the
``packaging/debian`` of each repository, the build dependencies,
``debuild``), for the repositories of ``ADI_PACKAGES`` (in the script) at
fixed commits. Each build environment is a Debian of the release and snapshot
of ``config``, made by ``mmdebstrap`` without root and thrown away after the
build: cross-compiled in an ``amd64`` environment by default, natively in a
``riscv64`` one under qemu for the packaging that does not cross-compile
(Python extensions, GNU Radio), as the ADI CI builds ``arm64`` natively. A
package already in the repository at its version (the highest version tag +
the commit, as the ADI CI) is not built again. The build environments trust the
certificates of the build host (``/etc/ssl/certs/ca-certificates.crt``):
behind a TLS-inspecting proxy, install the certificate of the proxy on the
build host.

The sources are in ``kuiper-build-temp/riscv64-packages``, the build
environments in ``kuiper-build-env-<uid>-<id>`` of ``KUIPER_BUILD_ENV_TEMP``
(default ``TMPDIR``, or ``/tmp``), during the build only: they are removed at
the end, also when the build fails or is interrupted, and at the start, if a
killed run left them. ``mmdebstrap`` builds without root in a user namespace,
whose root is the first subordinate uid of the user (``/etc/subuid``); it
must reach the build environments, with the search (``x``) permission on the
directories above them. A home directory of mode 750 does not let it pass, so
``KUIPER_BUILD_ENV_TEMP=kuiper-build-temp`` needs e.g. ``setfacl -m
u:<subordinate uid>:x <home>`` (or ``chmod o+x <home>``). The tool checks it
first and names the directory that it cannot pass; it does not change the
permissions.

Differences from the ADI packages (``tools/riscv64/adi-packages``):

- ``libm2k``: no ``libm2k-csharp``, Debian has no ``riscv64`` Mono runtime;
- ``iio-oscilloscope``: the ADI package repackages the AppImage, which has no
  ``riscv64`` build; it is built from source with the ``debian/`` of the
  repository, under the name the stage installs;
- ``gt``: the packaging of the USB Gadget Tool, which ``adi-scripts``
  depends on and whose ADI packaging is not public;
- Scopy is not built (an AppImage too).

PolarFire SoC boot files
~~~~~~~~~~~~~~~~~~~~~~~~

.. shell::

   $tools/mpfs/build-boot-files.sh -k <build>

It builds the ``adi-mpfs-boot`` package into the same repository, for the
boards of ``tools/mpfs/boards``. U-Boot, its environment and the HSS payload
are built as the Microchip Yocto BSP (``meta-mchp``) builds them for the
board, from ``meta-mchp``, U-Boot (the commit of the ``meta-mchp`` recipe,
with the board configuration fragment) and the HSS
(``hss-payload-generator``) at the fixed commits of ``board.conf``,
reproducibly. The root file system is on partition 2, as on the other
Kuiper images (the ``rootpart`` of ``uboot.env``).

The image
~~~~~~~~~

With the settings of ``tools/mpfs/mpfs.config`` in ``config``, the image is
built as any Kuiper image:

.. shell::

   $sudo bash build-docker.sh

----

Boot Partition and Image
------------------------

The HSS in the eNVM of the board (the Hart Software Services, with the FPGA
design of the HDL project, programmed with its job file) loads U-Boot from the
partition of the BIOS boot type of the SD card. U-Boot loads ``uboot.env`` and
runs ``boot.scr`` from the BOOT partition, which boots the kernel ``Image``
with the devicetree ``mss.dtb``.

The image keeps the Kuiper partitions, in a GPT (the HSS needs it): the BOOT
FAT32 partition first, the root file system second (it grows to the end of
the SD card at the first boot), the bootloader partition third, at the start
of the image, of the BIOS boot type, with the payload (U-Boot) of the board.

The boot files of ``adi-mpfs-boot``, laid out as the ones of the other
architectures:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - File
     - Description
   * - ``mpfs-common/Image``
     - The kernel, common to the projects
   * - ``<target>/<specific_folder>/mss.dtb``
     - The devicetree of a project, e.g.
       ``mpfs-sev-kit-ad936x-fmcomms2-3-4/mpfs-sev-kit-ad9361-fmcomms2-3/mss.dtb``
   * - ``<board>/payload.bin``
     - U-Boot in the HSS payload format: the preloader of the projects of the
       board, written to the bootloader partition
   * - ``<board>/boot.scr``, ``<board>/uboot.env``
     - The boot script and the U-Boot environment of the board
   * - ``kuiper.json``
     - The projects: ``fmcomms2``, ``fmcomms3`` and ``fmcomms4`` on
       ``mpfs_video_kit``

As on the other Kuiper images, ``configure-setup.sh`` prepares the boot
partition for a project: it copies the kernel and the files of the project
(``mss.dtb``, ``boot.scr``, ``uboot.env``) to the root of the BOOT partition:

.. shell::

   $sudo configure-setup.sh fmcomms2 mpfs_video_kit

On the board, the PolarFire SoC images also have:

- the root autologin on the Linux console, MMUART1 (``ttyS1``);
- the login console on the ACM serial port of the USB gadget (``ttyGS0``)
  without the TTY reset of systemd: systemd resets the console terminals
  under one lock, and the reset of ``ttyGS0`` would block while no USB host
  reads the port, so ``ttyS1`` would get no login prompt;
- iiod over the USB gadget with 2 endpoint pairs: the USB controller of the
  PolarFire SoC has 4 IN and 4 OUT endpoints, and the ACM serial function of
  the gadget takes 2 IN and 1 OUT;
- ``README_serial_iio.txt`` on the BOOT partition: how to serve IIO on the
  USB serial port instead.

----

Differences on riscv64
----------------------

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Component
     - riscv64
   * - Chromium
     - Debian has no ``riscv64`` build: ``firefox-esr`` instead
       (``PACKAGE_SUBSTITUTES``)
   * - Scopy
     - Not installed: its AppImage has no ``riscv64`` build
   * - ``libm2k-csharp``
     - Not installed: Debian has no ``riscv64`` Mono runtime
   * - ADI packages
     - From ``ADI_LOCAL_REPO`` (``tools/riscv64/build-adi-packages.sh``)
   * - Boot files
     - ``adi-mpfs-boot`` from ``ADI_LOCAL_REPO``
       (``tools/mpfs/build-boot-files.sh``)

----

Adding a Board
--------------

A new PolarFire SoC board is a new folder in ``tools/mpfs/boards``, as
``mpfs-video-kit``: ``board.conf`` (its names in ``kuiper.json``, its
projects and devicetrees, the ``meta-mchp``, U-Boot and HSS settings) and
``boot.cmd`` (its boot script).

----

Towards the ADI Package Repository
----------------------------------

The local package repository stands for packages that the ADI package
repository does not have yet. With them there, ``ADI_LOCAL_REPO`` and the
tools are no longer needed, and the PolarFire SoC images build as the others:

- the ADI packages for ``riscv64``: the ``deb-generator-action`` of the CI
  of each ADI repository with a ``riscv64`` build (the steps of
  ``tools/riscv64/build-adi-packages.sh``);
- ``adi-mpfs-boot``: built in the CI with the boot files of the other
  architectures, from the ADI Linux build of ``adi_mpfs_defconfig`` (the
  steps of ``tools/mpfs/build-boot-files.sh``).
