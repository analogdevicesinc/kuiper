.. _configuration:

Configuration
=============

Kuiper-gen's build process is controlled by settings defined in the ``config`` 
file located in the root of the repository. This file contains bash variables 
that determine what features to include and how to build the image.

----

How to Configure
----------------

To modify the configuration:

1. Edit the ``config`` file in your preferred text editor
2. Set option values to ``y`` to enable features or ``n`` to disable them
3. Modify other values as needed for your build
4. Save the file and run the build script

After the build completes, you can find a copy of the used configuration in 
the root directory (``/``) of the built image.

You can also set the number of processors or cores you want to use for 
building by adding ``NUM_JOBS=[number]`` to the config file. By default, 
this uses all available cores (``$(nproc)``).

----

System Configuration
--------------------

These options control the fundamental aspects of your Kuiper image:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``TARGET_ARCHITECTURE``
     - ``armhf``
     - Target architecture: ``armhf`` (32-bit) or ``arm64`` (64-bit)
   * - ``DEBIAN_VERSION``
     - ``bookworm``
     - Debian version to use (e.g., ``bookworm``, ``bullseye``). Other 
       versions may have missing functionalities or unsupported tools

----

Build Process Options
---------------------

These options control how the Docker build process behaves:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``PRESERVE_CONTAINER``
     - ``n``
     - Keep the Docker container after building (``y``/``n``)
   * - ``CONTAINER_NAME``
     - ``debian_<DEBIAN_VERSION>_rootfs_container``
     - Name of the Docker container. Useful for building multiple 
       images in parallel
   * - ``EXPORT_SOURCES``
     - ``n``
     - Download source files for all packages in the image (``y``/``n``)

----

Desktop Environment
-------------------

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``CONFIG_DESKTOP``
     - ``n``
     - Install XFCE desktop environment and X11VNC server (``y``/``n``)

----

ADI Libraries and Tools
-----------------------

These options control which ADI libraries and tools are included in the image:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``CONFIG_LIBIIO``
     - ``n``
     - Install Libiio library (``y``/``n``)
   * - ``CONFIG_LIBIIO_CMAKE_ARGS``
     - *(see config file)*
     - CMake build arguments for Libiio
   * - ``BRANCH_LIBIIO``
     - ``libiio-v0``
     - Git branch to use for Libiio
   * - ``CONFIG_PYADI``
     - ``n``
     - Install Pyadi library (``y``/``n``). Requires Libiio
   * - ``BRANCH_PYADI``
     - ``main``
     - Git branch to use for Pyadi
   * - ``CONFIG_LIBM2K``
     - ``n``
     - Install Libm2k library (``y``/``n``). Requires Libiio
   * - ``CONFIG_LIBM2K_CMAKE_ARGS``
     - *(see config file)*
     - CMake build arguments for Libm2k
   * - ``BRANCH_LIBM2K``
     - ``main``
     - Git branch to use for Libm2k
   * - ``CONFIG_LIBAD9166_IIO``
     - ``n``
     - Install Libad9166 library (``y``/``n``). Requires Libiio
   * - ``CONFIG_LIBAD9166_IIO_CMAKE_ARGS``
     - *(see config file)*
     - CMake build arguments for Libad9166
   * - ``BRANCH_LIBAD9166_IIO``
     - ``libad9166-iio-v0``
     - Git branch to use for Libad9166
   * - ``CONFIG_LIBAD9361_IIO``
     - ``n``
     - Install Libad9361 library (``y``/``n``). Requires Libiio
   * - ``CONFIG_LIBAD9361_IIO_CMAKE_ARGS``
     - *(see config file)*
     - CMake build arguments for Libad9361
   * - ``BRANCH_LIBAD9361_IIO``
     - ``libad9361-iio-v0``
     - Git branch to use for Libad9361
   * - ``CONFIG_GRM2K``
     - ``n``
     - Install GRM2K (``y``/``n``). Requires Libiio, Libm2k, and Gnuradio
   * - ``CONFIG_GRM2K_CMAKE_ARGS``
     - *(see config file)*
     - CMake build arguments for GRM2K
   * - ``BRANCH_GRM2K``
     - ``main``
     - Git branch to use for GRM2K
   * - ``CONFIG_LINUX_SCRIPTS``
     - ``n``
     - Install ADI Linux scripts (``y``/``n``)
   * - ``BRANCH_LINUX_SCRIPTS``
     - ``kuiper2.0``
     - Git branch to use for Linux scripts

----

ADI Applications
----------------

These options control which ADI applications are included in the image:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``CONFIG_IIO_OSCILLOSCOPE``
     - ``n``
     - Install IIO Oscilloscope (``y``/``n``). Requires Libiio, 
       Libad9166_IIO, and Libad9361_IIO
   * - ``CONFIG_IIO_OSCILLOSCOPE_CMAKE_ARGS``
     - *(see config file)*
     - CMake build arguments for IIO Oscilloscope
   * - ``BRANCH_IIO_OSCILLOSCOPE``
     - ``v0.18-main``
     - Git branch to use for IIO Oscilloscope
   * - ``CONFIG_IIO_FM_RADIO``
     - ``n``
     - Install IIO FM Radio (``y``/``n``)
   * - ``BRANCH_IIO_FM_RADIO``
     - ``main``
     - Git branch to use for IIO FM Radio
   * - ``CONFIG_FRU_TOOLS``
     - ``n``
     - Install FRU tools (``y``/``n``)
   * - ``BRANCH_FRU_TOOLS``
     - ``main``
     - Git branch to use for FRU tools
   * - ``CONFIG_JESD_EYE_SCAN_GTK``
     - ``n``
     - Install JESD Eye Scan GTK (``y``/``n``)
   * - ``CONFIG_JESD_EYE_SCAN_GTK_CMAKE_ARGS``
     - *(see config file)*
     - CMake build arguments for JESD Eye Scan GTK
   * - ``BRANCH_JESD_EYE_SCAN_GTK``
     - ``main``
     - Git branch to use for JESD Eye Scan GTK
   * - ``CONFIG_COLORIMETER``
     - ``n``
     - Install Colorimeter (``y``/``n``). Requires Libiio
   * - ``BRANCH_COLORIMETER``
     - ``main``
     - Git branch to use for Colorimeter
   * - ``CONFIG_SCOPY``
     - ``n``
     - Install Scopy (``y``/``n``)

----

Non-ADI Applications
--------------------

These options control which non-ADI applications are included in the image:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``CONFIG_GNURADIO``
     - ``n``
     - Install GNU Radio (``y``/``n``)

----

Boot Files Configuration
------------------------

These options control which boot files are included in your image:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``CONFIG_RPI_BOOT_FILES``
     - ``y``
     - Include Raspberry Pi boot files (``y``/``n``) - **Enabled by default**
   * - ``CONFIG_ARCH_ZYNQ``
     - ``y``
     - Install Zynq architecture boot files (``y``/``n``).
   * - ``CONFIG_ARCH_ARRIA10``
     - ``y``
     - Install Arria10 architecture boot files (``y``/``n``).
   * - ``CONFIG_ARCH_CYCLONE5``
     - ``y``
     - Install Cyclone5 architecture boot files (``y``/``n``).
   * - ``CONFIG_ARCH_ZYNQMP``
     - ``n``
     - Install ZynqMP architecture boot files (``y``/``n``).
   * - ``CONFIG_ARCH_VERSAL``
     - ``n``
     - Install Versal architecture boot files (``y``/``n``).

**Architecture to Hardware Mapping:**

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Architecture
     - Hardware Platform Examples
   * - ``zynq``
     - ZedBoard, ZC702, ZC706, Cora Z7s, ADRV9361-Z7035, ADRV9364-Z7020
   * - ``arria10``
     - Arria10 SoC Development Kit
   * - ``cyclone5``
     - Cyclone 5 SoC Kit, DE10-Nano, Arradio board
   * - ``zynqmp``
     - ZCU102, ADRV9009-ZU11EG, Jupiter SDR
   * - ``versal``
     - VCK190, VPK180, VHK158

----

.. _configuration-hardware-targeting:

Hardware Targeting Configuration
--------------------------------

These options configure your image for specific hardware during the build 
process:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``ADI_EVAL_BOARD``
     - *(empty)*
     - Configure which ADI evaluation board project the image will run. 
       When set, the image will be pre-configured for this specific project. 
   * - ``CARRIER``
     - *(empty)*
     - Configure which carrier board the image will boot on. Used together 
       with ``ADI_EVAL_BOARD`` to create a ready-to-use hardware configuration

**Note:** Setting ``ADI_EVAL_BOARD`` and ``CARRIER`` is optional. You can leave 
these empty and configure your hardware later using the runtime 
``configure-setup.sh`` script. See :doc:`Hardware Configuration 
<hardware-configuration>` for details.

----

Platform-Specific Packages
--------------------------

These options add platform-specific software packages beyond the basic boot 
files:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``INSTALL_RPI_PACKAGES``
     - ``n``
     - Install Raspberry Pi specific packages (``y``/``n``) including: 
       raspi-config, GPIO-related tools (pigpio, python3-gpio, raspi-gpio, 
       python3-rpi.gpio), VideoCore debugging (vcdbg), sense-hat, and sense-emu

----

Customization
-------------

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Option
     - Default
     - Description
   * - ``EXTRA_SCRIPT``
     - *(empty)*
     - Path to a custom script inside the adi-kuiper-gen directory to run 
       during build for additional customization

----

Common Configuration Examples
-----------------------------

Building a 64-bit image with desktop environment
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash
   :caption: config file settings

   TARGET_ARCHITECTURE=arm64
   CONFIG_DESKTOP=y

Including IIO tools and libraries
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash
   :caption: config file settings

   CONFIG_LIBIIO=y
   CONFIG_IIO_OSCILLOSCOPE=y  # This will require LIBAD9166_IIO and LIBAD9361_IIO

Building for a specific ADI evaluation board
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash
   :caption: config file settings

   ADI_EVAL_BOARD=ad9361-fmcomms2
   CARRIER=zedboard

Building only 64-bit boot files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash
   :caption: config file settings

   CONFIG_ARCH_ZYNQ=n
   CONFIG_ARCH_ARRIA10=n
   CONFIG_ARCH_CYCLONE5=n

   CONFIG_ARCH_ZYNQMP=y
   CONFIG_ARCH_VERSAL=y

Complete development environment with GNU Radio
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash
   :caption: config file settings

   CONFIG_DESKTOP=y
   CONFIG_LIBIIO=y
   CONFIG_LIBM2K=y
   CONFIG_GNURADIO=y
   CONFIG_GRM2K=y
