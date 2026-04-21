.. _repositories:

Repositories
============

Kuiper uses multiple package repositories to install and update software. 
These repositories are configured during the build process in the bootstrap 
stage.

----

.. _repositories adi:

ADI Repository
--------------

The ADI APT repository is a collection of Debian package files that 
facilitates the distribution and installation of Analog Devices software 
packages. The repository contains .deb packages with boot files for carriers 
and Raspberry Pi.

**Advantages of using the ADI repository:**

- Easy installation, removal, and upgrading of packages (``apt install``, 
  ``apt remove``, ``apt upgrade``)
- Simplified version management
- Package manager handles dependency resolution and conflict detection
- Centralized distribution of ADI-specific packages

**Architecture-Specific Boot Packages:**

Boot files are organized by processor architecture. ADI provides packages for 
each supported architecture family:

.. list-table::
   :header-rows: 1

   * - Hardware Platform Examples
     - Architecture Package
   * - ZedBoard, ZC702, ZC706, Cora Z7s, ADRV9361-Z7035, ADRV9364-Z7020
     - ``adi-zynq-boot``
   * - ZCU102, ADRV9009-ZU11EG, Jupiter SDR
     - ``adi-zynqmp-boot``
   * - VCK190, VPK180, VHK158
     - ``adi-versal-boot``
   * - Arria10 SoC Development Kit
     - ``adi-arria10-boot``
   * - Cyclone 5 SoC Kit, DE10-Nano, Arradio board
     - ``adi-cyclone5-boot``
   * - Raspberry Pi
     - ``adi-rpi-boot``

ADI packages follow standard Debian conventions with consistent package names 
and version-based differentiation, allowing standard package management 
operations.

**Discovering Available Packages:**

To see all available ADI packages and their versions:

.. code-block:: bash

   apt search "adi-.*-boot"

To see detailed information about a specific package:

.. code-block:: bash

   apt show adi-zynq-boot

----

.. _repositories rpi:

Raspberry Pi Repository
-----------------------

By default, the Kuiper image includes the official Raspberry Pi package 
repository in ``/etc/apt/sources.list.d/raspi.list``. This repository 
provides access to Pi-specific packages and optimizations.

**Using the Raspberry Pi repository:**

1. Edit ``/etc/apt/sources.list.d/raspi.list`` and uncomment the first line
2. Update the package lists: ``sudo apt update``
3. Install packages as needed: ``sudo apt install <package-name>``

This gives you access to RPI-specific packages such as GPIO libraries, 
VideoCore tools, and other hardware-specific packages.

----

Install Packages
----------------

To install packages from either repository on your running Kuiper system:

.. code-block:: bash

   sudo apt update
   sudo apt install <package-name>

For example, to install boot files for your hardware architecture:

.. code-block:: bash

   sudo apt update
   sudo apt install adi-zynq-boot

To upgrade to a newer version when available:

.. code-block:: bash

   sudo apt update
   sudo apt upgrade adi-zynq-boot

