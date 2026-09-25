.. _stage-reference:

Stage Reference
===============

The Kuiper build is divided into several stages for logical clarity and 
modularity. This section describes each stage in detail, helping you understand 
the complete build process.

----

Stage 01: Bootstrap
-------------------

**Purpose**: Create a usable minimal filesystem

**Key operations**:

- Uses ``debootstrap`` to create a minimal Debian filesystem
- Sets up core system components
- Prepares for configuration in later stages

The minimal core is installed but not configured at this stage, and the system 
is not yet bootable.

----

Stage 02: Set Locale and Timezone
----------------------------------

**Purpose**: Configure system localization

**Key operations**:

- Installs localization packages (locales, dialog)
- Configures locale variables
- Sets the system timezone
- Installs mandatory system packages

**Related config options**: None (always executed)

----

Stage 03: System Tweaks
------------------------

**Purpose**: Configure core system settings and users

**Key operations**:

- Creates 'analog' user with sudo rights (password: 'analog')
- Sets root password (same as user: 'analog')
- Configures hostname
- Sets up root autologin
- Enables SSH root login
- Configures network settings
- Sets up automounting for external devices

**Related config options**: None (always executed)

----

Stage 04: Configure Desktop Environment
----------------------------------------

**Purpose**: Set up graphical interface (optional)

**Key operations**:

- Installs XFCE desktop environment
- Configures automatic login for 'analog' user
- Sets up X11VNC server for remote access
- Applies visual customizations

**Related config options**:

- ``CONFIG_DESKTOP=y`` - Enable/disable entire stage

----

Stage 05: ADI Tools
--------------------

**Purpose**: Install Analog Devices libraries and applications

**Key operations**:

- Installs selected ADI libraries: libiio, pyadi, libm2k, libad9361, libad9166, 
  gr-m2k
- Installs selected ADI applications: iio-oscilloscope, iio-fm-radio, 
  fru_tools, jesd-eye-scan-gtk, colorimeter, Scopy
- Installs non-ADI applications: GNU Radio
- Clones Linux scripts repository
- Creates log file with installed tools, branches, and commit hashes

**Related config options**: Multiple tool-specific options

- ``CONFIG_LIBIIO``, ``CONFIG_PYADI``, ``CONFIG_LIBM2K``, etc.
- See :doc:`ADI Libraries and Tools <configuration>`, :doc:`ADI Applications 
  <configuration>` and :doc:`Non-ADI Applications <configuration>` in 
  Configuration section

----

Stage 06: Boot Partition
-------------------------

**Purpose**: Prepare boot files for different platforms

**Key operations**:

- Adds Intel and Xilinx boot binaries (if configured)
- Adds Raspberry Pi boot files (if configured)
- Creates and configures fstab for mounting partitions
- Sets up default boot configuration for Raspberry Pi

**Related config options**:

- ``CONFIG_RPI_BOOT_FILES`` - Include Raspberry Pi boot files
- ``CONFIG_ARCH_ZYNQ``, ``CONFIG_ARCH_ARRIA10``, ``CONFIG_ARCH_CYCLONE5`` -
  Include Intel and Xilinx boot files for 32-bit architectures (armhf)
- ``CONFIG_ARCH_ZYNQMP``, ``CONFIG_ARCH_VERSAL`` - Include Intel and Xilinx
  boot files for 64-bit architectures (arm64)

----

Stage 07: Extra Tweaks
-----------------------

**Purpose**: Apply custom configurations and additions

**Key operations**:

- Runs custom user scripts (if specified)
- Installs Raspberry Pi specific packages (if configured)
- Installs Raspberry Pi WiFi firmware (if Raspberry Pi boot files are 
  configured)

**Related config options**:

- ``EXTRA_SCRIPT`` - Path to custom script
- ``INSTALL_RPI_PACKAGES`` - Install Raspberry Pi specific packages
- ``CONFIG_RPI_BOOT_FILES`` - Install Raspberry Pi WiFi firmware

----

Stage 08: Export Stage
-----------------------

**Purpose**: Finalize and export the image

**Key operations**:

- Installs scripts to extend rootfs partition on first boot
- Exports source code for all packages (if configured)
- Generates license information
- Prepares boot partition for target hardware
- Creates and compresses the final disk image into a zip file

**Related config options**:

- ``EXPORT_SOURCES`` - Download source files for all packages
- ``ADI_EVAL_BOARD`` and ``CARRIER`` - Configure for specific hardware
