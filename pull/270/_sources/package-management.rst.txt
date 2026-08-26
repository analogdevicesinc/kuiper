.. _package-management:

Package Management
==================

Kuiper uses package repositories to install and manage software. This page
explains the available repositories and how to install, update, and manage
packages on your Kuiper system.

----

.. _package-management-kuiper:

Kuiper Repository
-----------------

The Kuiper APT repository provides Debian packages for Analog Devices libraries,
applications, and boot files. All packages are pre-built, tested, and optimized
for Kuiper.

**Advantages of using the Kuiper repository:**

- Easy installation, removal, and upgrading of packages (``apt install``,
  ``apt remove``, ``apt upgrade``)
- Automatic dependency resolution and conflict detection
- Simplified version management
- Debug symbol packages available for most packages (``*-dbgsym``)

Available Packages
~~~~~~~~~~~~~~~~~~

ADI Libraries
+++++++++++++

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Package
     - Description
     - Additional Packages
   * - ``libiio0``
     - Library for interfacing with Linux IIO devices
     - ``libiio-dev``, ``libiio-utils``, ``python3-libiio``, ``iiod``
   * - ``libm2k``
     - Library for interfacing with the ADALM2000
     - ``libm2k-dev``, ``libm2k-tools``, ``python3-libm2k``, ``libm2k-csharp``
   * - ``libad9361``
     - Library for managing multi-chip sync and FIR filters for AD9361
     - ``libad9361-dev``, ``python3-libad9361``
   * - ``libad9166``
     - Library for calibration gain and offset for AD9166
     - ``libad9166-dev``, ``python3-libad9166``, ``libad9166-dbgsym``

ADI Applications
++++++++++++++++

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Package
     - Description
   * - ``iio-oscilloscope``
     - GTK+ application for interfacing with IIO devices
   * - ``scopy``
     - Software oscilloscope and signal analysis toolset
   * - ``colorimeter``
     - Application for the EVAL-CN0363-PMDZ (with ``colorimeter-dbgsym``)
   * - ``jesd-eye-scan-gtk``
     - JESD204 Eye Scan visualization utility (with ``jesd-eye-scan-gtk-dbgsym``)
   * - ``iio-fm-radio``
     - Simple IIO FM Radio receiver (with ``iio-fm-radio-dbgsym``)
   * - ``fru-tools``
     - Tools to display/manipulate FMC FRU info (with ``fru-tools-dbgsym``)
   * - ``gr-m2k``
     - GNU Radio blocks for ADALM-2000 (with ``gr-m2k-dev``, ``python3-gr-m2k``)
   * - ``adi-scripts``
     - ADI scripts for Linux images

Boot Files
++++++++++

Boot files are organized by processor architecture:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Hardware Platform Examples
     - Package
     - Architecture
   * - ZedBoard, ZC702, ZC706, Cora Z7s, ADRV9361-Z7035, ADRV9364-Z7020
     - ``adi-zynq-boot``
     - armhf
   * - ZCU102, ADRV9009-ZU11EG, Jupiter SDR
     - ``adi-zynqmp-boot``
     - arm64
   * - VCK190, VPK180, VHK158
     - ``adi-versal-boot``
     - arm64
   * - Arria10 SoC Development Kit
     - ``adi-arria10-boot``
     - armhf
   * - Cyclone 5 SoC Kit, DE10-Nano, Arradio board
     - ``adi-cyclone5-boot``
     - armhf
   * - Raspberry Pi
     - ``adi-rpi-boot``
     - armhf, arm64

Discovering Packages
~~~~~~~~~~~~~~~~~~~~

Search for all ADI packages:

.. code-block:: bash

   apt search adi

Search for specific package types:

.. code-block:: bash

   apt search libiio
   apt search "adi-.*-boot"

View detailed package information:

.. code-block:: bash

   apt show libiio0
   apt show iio-oscilloscope

Installing and Updating Packages
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install a package:

.. code-block:: bash

   sudo apt update
   sudo apt install libiio0

Install with development and Python bindings:

.. code-block:: bash

   sudo apt install libiio0 libiio-dev python3-libiio

Install with debug symbols:

.. code-block:: bash

   sudo apt install iio-oscilloscope iio-oscilloscope-dbgsym

Upgrade all installed packages:

.. code-block:: bash

   sudo apt update
   sudo apt upgrade

Upgrade a specific package:

.. code-block:: bash

   sudo apt update
   sudo apt upgrade libiio0

----

.. _package-management-rpi:

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

