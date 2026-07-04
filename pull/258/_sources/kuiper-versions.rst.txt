.. _kuiper-versions:

Kuiper Versions
===============

Depending on your configuration choices, different combinations of build stages 
and substages will be included. Here are the common build configurations:

----

.. _kuiper-versions-basic-image:

Basic Image (Default)
---------------------

The default configuration includes only the essential packages and 
configuration needed for a functional system:

- **01.bootstrap** - Core filesystem setup
- **02.set-locale-and-timezone** - Basic system localization
- **03.system-tweaks** - User and system configuration
- **05.adi-tools**

  - Substage **14.write-git-logs** - Build information tracking

- **06.boot-partition**

  - Substage **01.adi-boot-files** - Intel/Xilinx boot files (if enabled)
  - Substage **02.rpi-boot-files** - Raspberry Pi boot files (if enabled)
  - Substage **03.add-fstab** - Filesystem table configuration

- **07.extra-tweaks**

  - Substage **03.install-rpi-wifi-firmware** - WiFi support (if needed)

- **08.export-stage**

  - Substage **01.extend-rootfs** - Root filesystem expansion script
  - Substage **03.generate-license** License generation
  - Substage **04.export-image** - Final image creation

----

Optional Components
-------------------

These components can be added on top of the basic image:

- **Desktop Environment** (``CONFIG_DESKTOP=y``):

  - **04.configure-desktop-env**

    - Substage **01.desktop-env** - XFCE desktop
    - Substage **02.vnc-server** - Remote display access
    - Substage **03.cosmetic** - Visual customizations

- **ADI Tools** (various CONFIG\_\* options):

  - **05.adi-tools**

    - Substages for each tool (libiio, pyadi, libm2k, etc.)

- **Source Code Export** (``EXPORT_SOURCES=y``):

  - **08.export-stage**

    - Substage **02.export-sources** - Package source code collection

- **Custom Scripts** (``EXTRA_SCRIPT`` set):

  - **07.extra-tweaks**

    - Substage **01.extra-scripts** - Custom script execution
  - For detailed instructions, see the :doc:`Custom Script Integration 
    <customization>` section.

- **Raspberry Pi Packages** (``INSTALL_RPI_PACKAGES=y``):

  - **07.extra-tweaks**

    - Substage **02.install-rpi-packages** - RPI-specific packages
