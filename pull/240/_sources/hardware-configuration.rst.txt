.. _hardware-configuration:

Hardware Configuration
======================

.. description::

   Configure Kuiper images for ADI evaluation boards and Raspberry Pi
   platforms with automated tools and manual options for flexible deployment

Kuiper supports multiple hardware platforms, each with different setup
requirements:

**ADI Evaluation Boards**
   Require configuration to specify which evaluation board and carrier board
   combination you're using. This can be done during the build process or
   after deployment. Check out the :ref:`hardware-configuration-adi-eval-boards`
   dedicated section.

**Raspberry Pi**
   Works immediately after flashing with no configuration required. This
   section documents optional customizations like device tree overlays. Check 
   out the :ref:`hardware-configuration-raspberry-pi` dedicated section.

----

.. _hardware-configuration-adi-eval-boards:

ADI Evaluation Boards
---------------------

ADI evaluation boards require configuration to work with Kuiper images.
You must specify both your evaluation board (e.g., AD9361-FMCOMMS2) and
carrier board (e.g., ZedBoard, ZC706) so the system can load the
correct boot files.

Configuration Methods
~~~~~~~~~~~~~~~~~~~~~

Kuiper provides three configuration approaches:

**Build-Time Configuration**
   Set ``ADI_EVAL_BOARD`` and ``CARRIER`` parameters in your config file
   before building. Your image will be pre-configured for that hardware
   combination.

**On-Device Configuration**
   Use the ``configure-setup.sh`` script on your running Kuiper system
   to configure or switch between different hardware combinations.

**PC-Based Configuration**
   Use the ``configure-setup.sh`` script from your PC to prepare SD cards
   before deployment. Ideal for batch preparation or when the target device
   isn't accessible.

Automated Configuration
~~~~~~~~~~~~~~~~~~~~~~~

The ``configure-setup.sh`` script is the recommended method for configuring
your Kuiper image. The script handles all technical details automatically,
including copying files, updating configurations, and writing bootloaders
for Intel platforms.

.. note::

   For PC users: The script is located at ``/usr/local/bin/configure-setup.sh``
   on your Kuiper image. Access it by mounting the SD card's rootfs partition,
   or download it from :git-adi-kuiper-gen:`here
   <blob/main/stages/08.export-stage/04.export-image/files/configure-setup.sh+>`.

Discovering Available Hardware
++++++++++++++++++++++++++++++

Before configuring, check which hardware combinations your Kuiper image
supports.

On device:

.. shell::

   $sudo configure-setup.sh --help

From PC with mounted SD card:

.. shell::

   $sudo configure-setup.sh --boot-partition /media/$USER/BOOT --help

Example output:

.. shell::

   Usage:
     sudo configure-setup.sh [OPTIONS] <eval-board> <carrier> [bootloader-dev]

   Description:
     Script that prepares Kuiper image to boot on a carrier board.

   Arguments:
     eval-board            Name of the project
     carrier               Carrier board name
     bootloader-dev        Bootloader device (default: /dev/mmcblk0p3)

   Options:
     -b, --boot-partition PATH     Path to boot partition (default: /boot)
     -h, --help                    Show this help message

   Note: Options must be specified before positional arguments.

   Examples:
     # Running directly on the board:
     sudo configure-setup.sh ad4003 zed
     sudo configure-setup.sh --help

     # Configuring SD card from PC:
     sudo configure-setup.sh -b /media/$USER/BOOT ad4003 zed
     sudo configure-setup.sh -b /media/$USER/BOOT --help
     sudo configure-setup.sh -b /media/$USER/BOOT <intel-project> <intel-carrier> /dev/sdb3


   Available projects in your Kuiper image:

   ADI Eval Board    Carrier
   ad9361-fmcomms2   zed
   ad9361-fmcomms2   zc706
   ad4003            zed
   adrv9009-zu11eg   adrv9009-zu11eg-revb

This output shows all evaluation board and carrier board combinations that
your specific Kuiper image supports.

On-Device Configuration
+++++++++++++++++++++++

Configure your hardware directly on a running Kuiper system. The ``analog``
user has sudo privileges.

Follow these steps:

#. **Log into your Kuiper system** via console, SSH, or VNC.

#. **Check available configurations** (if you haven't already):

   .. shell::

      $sudo configure-setup.sh --help

#. **Run the configuration command**:

   .. shell::

      $sudo configure-setup.sh <eval-board> <carrier>

   For example, to configure for AD9361-FMCOMMS2 on ZedBoard:

   .. shell::

      $sudo configure-setup.sh ad9361-fmcomms2 zed
       Successfully prepared boot partition for running project ad9361-fmcomms2 on zed.

#. **Reboot or shutdown**:

   **If staying on the same carrier board** (just switching evaluation boards):

   .. shell::

      $sudo reboot

   **If moving SD card to a different carrier board**:

   .. shell::

      $sudo shutdown -h now

   Then remove the SD card, insert it into the new carrier board, and power on.

.. important::

   **Why different shutdown procedures?**
   
   * **Reboot** is safe and fast when the SD card stays in the same hardware
   * **Shutdown** ensures all pending writes complete before physically moving
     the card between devices, preventing potential corruption
   * Configuration changes take effect only after a complete boot cycle

PC-Based Configuration
++++++++++++++++++++++

Configure SD cards from your PC before deploying to hardware.

#. **Insert SD card into your PC** and identify the boot partition mount
   point (typically ``/media/$USER/BOOT``).

#. **Check available configurations**:

   .. shell::

      $sudo configure-setup.sh --boot-partition /media/$USER/BOOT --help

#. **Configure for your target hardware**:

   For AMD/Xilinx platforms (Zynq, ZynqMP, Versal):

   .. shell::

      $sudo configure-setup.sh --boot-partition /media/$USER/BOOT <eval-board> <carrier>

   Example:

   .. shell::

      $sudo configure-setup.sh -b /media/$USER/BOOT ad9361-fmcomms2 zed
       Successfully prepared boot partition for running project ad9361-fmcomms2 on zed.

   For Intel platforms (Arria10, Cyclone5) - you must specify the bootloader device:

   .. shell::

      $sudo configure-setup.sh -b /media/$USER/BOOT <eval-board> <carrier> /dev/sdb3

   Example:

   .. shell::

      $sudo configure-setup.sh -b /media/$USER/BOOT de10-nano socdk /dev/sdb3
       Successfully prepared boot partition for running project de10-nano on socdk.

   .. note::

      Intel platforms require writing a preloader to a dedicated bootloader
      partition. When configuring from a PC, identify the correct device:

      * Use ``lsblk`` to find your SD card (typically ``/dev/sdb`` or ``/dev/sdc``)
      * The bootloader partition is the small 4MB partition (e.g., ``/dev/sdb3``)
      * On the device itself, this is always ``/dev/mmcblk0p3`` (the default)
      * AMD/Xilinx platforms don't need this parameter

#. **Safely eject the SD card** from your PC.

#. **Insert into target hardware** and power on.

What Happens During Configuration
+++++++++++++++++++++++++++++++++

When you run the configuration script, it performs these operations:

#. **Identifies required files** for your specific evaluation board and
   carrier board combination

#. **Copies boot files** to the boot partition, including:

   * Kernel image (Image, uImage, or zImage depending on platform)
   * Device tree files
   * Platform-specific files (BOOT.BIN, boot.scr, U-Boot configurations)

#. **For Intel platforms only**, performs additional steps:

   * Creates the ``extlinux/`` directory structure
   * Writes the preloader to the bootloader partition

#. **Verifies each operation** and reports success or failure

Configuration Examples
++++++++++++++++++++++

**Switching Evaluation Boards on Same Carrier**

Testing different evaluation boards on the same carrier board:

.. shell::

   $sudo configure-setup.sh ad4003 zed
    Successfully prepared boot partition for running project ad4003 on zed.
   $sudo reboot

Later, switch to a different evaluation board:

.. shell::

   $sudo configure-setup.sh ad9361-fmcomms2 zed
    Successfully prepared boot partition for running project ad9361-fmcomms2 on zed.
   $sudo reboot

**Moving Between Different Carrier Boards**

When switching to a different carrier board:

.. shell::

   $sudo configure-setup.sh ad9361-fmcomms2 zed
    Successfully prepared boot partition for running project ad9361-fmcomms2 on zed.
   $sudo shutdown -h now

After shutdown, remove the SD card from ZedBoard, insert it into ZC706, then
power on.

**Preparing Multiple SD Cards from PC**

Configure several SD cards for different hardware without booting devices:

.. shell::

   # Insert first SD card
   $sudo configure-setup.sh -b /media/$USER/BOOT ad9361-fmcomms2 zed
    Successfully prepared boot partition for running project ad9361-fmcomms2 on zed.

   # Eject, insert second SD card
   $sudo configure-setup.sh -b /media/$USER/BOOT ad4003 zc706
    Successfully prepared boot partition for running project ad4003 on zc706.

Each SD card is now ready for immediate deployment.

Common Workflows
~~~~~~~~~~~~~~~~

**Single Hardware Target**
   Set ``ADI_EVAL_BOARD`` and ``CARRIER`` during build for automatic
   configuration. Your image boots ready to use.

**Multi-Hardware Development**
   Build with your primary hardware configured, then use on-device
   configuration to test other combinations as needed.

**Lab/Evaluation Setup**
   Build without specifying hardware, then configure each SD card for
   specific hardware using PC-based configuration.

**Production Deployment**
   Use PC-based configuration to prepare multiple SD cards efficiently
   without booting each target device.

Manual Configuration (Advanced)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Manual configuration may be necessary when:

* The automated script fails or reports errors
* You need custom modifications beyond standard configurations
* Your Kuiper system isn't functioning and the script is unavailable
* You're troubleshooting boot issues and need to understand the process

The manual process involves the same file operations that the automated
script performs, but gives you direct control over each step.

Understanding the Configuration Process
+++++++++++++++++++++++++++++++++++++++

The automated script performs these technical steps:

#. **Searches** the boot partition for configuration metadata about
   available hardware combinations

#. **Identifies** which files are needed for your specific evaluation
   board and carrier board

#. **Copies** all required files to the boot partition

#. **For Intel platforms**, creates directory structures and writes
   bootloader files to the dedicated bootloader partition using low-level
   disk operations

#. **Validates** that each file operation completed successfully

Understanding these steps helps when performing manual configuration or
troubleshooting failures.

Platform-Specific Manual Steps
++++++++++++++++++++++++++++++

.. important::

   Manual configuration requires working with the SD card's boot
   partition. Always ensure the SD card is properly unmounted from your
   target hardware before modifying files on a host PC.

.. note::

   If required boot files are missing from your Kuiper image, install
   them using the ADI package repository. See the :doc:`Repositories
   <repositories>` section for detailed instructions.

AMD/Xilinx Platforms
....................

**For Zynq projects** (ZedBoard, ZC702, ZC706), copy these files to the
root of the BOOT FAT32 partition:

#. ``<target>/BOOT.BIN`` - First stage bootloader with FPGA bitstream
#. ``<target>/<specific_folder>/devicetree.dtb`` - Device tree for your
   specific project
#. ``zynq-common/uImage`` - Kernel image for Zynq platforms
#. ``zynq-common/uEnv.txt`` - U-Boot environment configuration

**For ZynqMP projects** (ZCU102, ADRV9009-ZU11EG), copy these files to
the root of the BOOT FAT32 partition:

#. ``<target>/BOOT.BIN`` - First stage bootloader with FPGA bitstream
#. ``<target>/<specific_folder>/system.dtb`` - Device tree for your
   specific project
#. ``zynqmp-common/Image`` - Kernel image for ZynqMP platforms
#. ``zynqmp-common/uEnv.txt`` - U-Boot environment configuration

**For Versal projects** (VCK190, VPK180, VHK158), copy these files to the root
of the BOOT FAT32 partition:

#. ``<target>/BOOT.BIN`` - Platform Loader and Manager (PLM) and boot
   components
#. ``<target>/<specific_folder>/system.dtb`` - Device tree for your
   specific project
#. ``<target>/boot.scr`` - U-Boot script for Versal boot sequence
#. ``versal-common/Image`` - Kernel image for Versal platforms

Intel/Altera Platforms
......................

Intel platforms require additional steps beyond copying files to the boot
partition. You must also write preloader files to a dedicated bootloader
partition.

**For Arria10 SoC projects**, copy these files to the root of the BOOT
FAT32 partition:

#. ``<target>/fit_spl_fpga.itb`` - FPGA configuration and SPL image
#. ``<target>/socfpga_arria10_socdk_sdmmc.dtb`` - Device tree
#. ``<target>/u-boot.img`` - U-Boot proper
#. ``socfpga_arria10_common/zImage`` - Kernel image
#. Create an ``extlinux`` folder and copy
   ``socfpga_arria10_common/extlinux.conf`` into it

Then write the preloader:

.. shell::

   $sudo dd if=<target>/fit_spl_fpga.itb of=/dev/mmcblk0p3 bs=512 status=progress

Replace ``mmcblk0p3`` with your actual bootloader partition device.

**For Cyclone5 projects** (DE10-Nano, Cyclone V SoC Kit), copy these
files to the root of the BOOT FAT32 partition:

#. ``<target>/soc_system.rbf`` - FPGA bitstream
#. ``<target>/socfpga.dtb`` - Device tree
#. ``<target>/u-boot.scr`` - U-Boot script
#. ``<target>/u-boot-with-spl.sfp`` - SPL and U-Boot combined
#. ``socfpga_cyclone5_common/zImage`` - Kernel image
#. Create an ``extlinux`` folder and copy
   ``socfpga_cyclone5_common/extlinux.conf`` into it

Then write the preloader:

.. shell::

   $sudo dd if=<target>/u-boot-with-spl.sfp of=/dev/mmcblk0p3 bs=512 status=progress

Replace ``mmcblk0p3`` with your actual bootloader partition device.

Finding the Bootloader Partition
................................

For Intel platforms, identify the correct partition for the preloader.

.. shell::

   $lsblk

Example output on PC:

.. shell::
   :no-path:

   $lsblk
    NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sdb      8:16   1  29.7G  0 disk
    ├─sdb1   8:17   1   256M  0 part /media/user/BOOT
    ├─sdb2   8:18   1  29.2G  0 part /media/user/rootfs
    └─sdb3   8:19   1     4M  0 part

In this case, ``/dev/sdb3`` is the 4MB bootloader partition.

Example output on target board:

.. shell::
   :no-path:

   $lsblk
    NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    mmcblk0     179:0    0 29.7G  0 disk
    ├─mmcblk0p1 179:1    0  256M  0 part /mnt/BOOT
    ├─mmcblk0p2 179:2    0 29.2G  0 part
    └─mmcblk0p3 179:3    0    4M  0 part

In this case, ``/dev/mmcblk0p3`` is the 4MB bootloader partition.

----

.. _hardware-configuration-raspberry-pi:

Raspberry Pi
------------

Raspberry Pi images work out-of-box without configuration. The SD card
boots immediately after flashing - no setup required.

This section covers optional customizations you can make after your
system is running.

Device Tree Overlays
~~~~~~~~~~~~~~~~~~~~

Raspberry Pi uses device tree overlays to enable additional hardware
features or configure peripherals. There are two methods to load
overlays.

Method 1: Persistent Configuration
+++++++++++++++++++++++++++++++++++

Edit ``/boot/config.txt`` to automatically load overlays on every boot.

#. Open the configuration file and add a new line with your overlay:

   .. code-block:: text

      dtoverlay=<overlay_name>[,<overlay_arguments>]

   For example:

   .. code-block:: text

      dtoverlay=spi0-1cs

#. Save the file and reboot:

   .. shell::

      $sudo reboot

Changes take effect after reboot.

Method 2: Dynamic Loading
+++++++++++++++++++++++++

Load overlays at runtime without rebooting or modifying configuration files.
Raspberry Pi package ``raspi-utils-dt`` needs to be installed for this method,
see :ref:`hardware-configuration-dtoverlay`.

.. shell::

   $sudo dtoverlay <overlay_name>[,<overlay_arguments>]

For example:

.. shell::

   $sudo dtoverlay spi0-1cs

.. note::

   Dynamically loaded overlays are lost on reboot. Use Method 1 for
   permanent configuration.

Available Overlays
~~~~~~~~~~~~~~~~~~

Overlay binaries (``*.dtbo``) are located in ``/boot/overlays``.

To list available overlays:

.. shell::

   $ls /boot/overlays/
    rpi-ad7091r8.dtbo
    rpi-ad7124-8-all-diff.dtbo
    rpi-ad7124.dtbo
    rpi-ad7173.dtbo
    rpi-ad7190.dtbo
    rpi-ad7191.dtbo
    rpi-ad7293.dtbo
    ...

.. important::

   Specify only the overlay name without extension or path. For example,
   use ``dtoverlay=my-overlay`` not
   ``dtoverlay=/boot/overlays/my-overlay.dtbo``.

.. _hardware-configuration-dtoverlay:

Device tree manipulation utility
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To manage the Device Tree using the ``dtoverlay`` command-line tool, first
enable the :ref:`repositories rpi`, then install the ``raspi-utils-dt``
package:

.. shell::

   $sudo apt install raspi-utils-dt
    The following NEW packages will be installed:
     libdtovl0 raspi-utils-dt

The ``raspi-utils-dt`` package provides the ``dtoverlay`` command-line utility,
which uses the ``libdtovl0`` library to manipulate Device Tree overlays.

Common Overlay Use Cases
~~~~~~~~~~~~~~~~~~~~~~~~

Here are typical scenarios for using device tree overlays:

**Enable SPI Interface**

.. shell::

   $sudo dtoverlay spi0-1cs

Or in ``/boot/config.txt``:

.. code-block:: text

   dtoverlay=spi0-1cs

**Load ADI Evaluation Board Overlay**

For ADI-specific overlays (assuming they exist in ``/boot/overlays``):

.. shell::

   $sudo dtoverlay rpi-ad7191

Or in ``/boot/config.txt``:

.. code-block:: text

   dtoverlay=rpi-ad7191

Removing Overlays
~~~~~~~~~~~~~~~~~

To remove a dynamically loaded overlay:

.. shell::

   $sudo dtoverlay -r <overlay_name>

For overlays in ``/boot/config.txt``, comment out or delete the line and
reboot.
