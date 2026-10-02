.. _releases:

Releases
========

.. description::

   ADI Kuiper Linux releases - tested and stable images in 32-bit and 64-bit
   variants, each available as a Basic or Full build

Releases are tested, stable Kuiper images that we recommend for most users.
Every release is a **Kuiper 2** image. If you have an existing SD card and are
unsure which generation it holds, see :ref:`checking-your-kuiper-version`. If
you want to check the list of supported projects, see
:ref:`supported-projects`.

.. note::

   Kuiper 1 is the previous generation. It is **deprecated** and no longer
   maintained. New releases are Kuiper 2 only.

----

.. _releases-downloads:

Downloads
---------

The current release is **Kuiper 2026.1.0**. Each variant ships as an
**image** (the SD-card image, write it with :doc:`these steps
<use-kuiper-image>`) and a **metadata** archive. The Full editions are
recommended for most users; the Basic editions are available below under
*Advanced*.

Full editions (recommended):

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Variant
     - Image
     - Metadata
   * - ARM 32-bit Full (``armhf``)
     - `Image <https://packages.analog.com/public/raw/files/kuiper_full_32_image_2026.1.0.zip>`__
     - `Metadata <https://packages.analog.com/public/raw/files/kuiper_full_32_meta_2026.1.0.zip>`__
   * - ARM 64-bit Full (``arm64``)
     - `Image <https://packages.analog.com/public/raw/files/kuiper_full_64_image_2026.1.0.zip>`__
     - `Metadata <https://packages.analog.com/public/raw/files/kuiper_full_64_meta_2026.1.0.zip>`__

.. collapsible:: Advanced: Basic editions

   The Basic editions are minimal images without a desktop environment or the
   ADI software stack. See :ref:`Basic Edition <releases-basic-image>` for
   details.

   .. list-table::
      :header-rows: 1
      :class: bold-header

      * - Variant
        - Image
        - Metadata
      * - ARM 32-bit Basic (``armhf``)
        - `Image <https://packages.analog.com/public/raw/files/kuiper_basic_32_image_2026.1.0.zip>`__
        - `Metadata <https://packages.analog.com/public/raw/files/kuiper_basic_32_meta_2026.1.0.zip>`__
      * - ARM 64-bit Basic (``arm64``)
        - `Image <https://packages.analog.com/public/raw/files/kuiper_basic_64_image_2026.1.0.zip>`__
        - `Metadata <https://packages.analog.com/public/raw/files/kuiper_basic_64_meta_2026.1.0.zip>`__

----

Release Variants
----------------

Each release is published in four variants, one for every combination of
**architecture** (32-bit or 64-bit) and **edition** (Basic or Full):

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Variant
     - Architecture
     - Edition
   * - ARM 32-bit Basic
     - ``armhf`` (32-bit)
     - Basic
   * - ARM 32-bit Full
     - ``armhf`` (32-bit)
     - Full
   * - ARM 64-bit Basic
     - ``arm64`` (64-bit)
     - Basic
   * - ARM 64-bit Full
     - ``arm64`` (64-bit)
     - Full

Choose the **architecture** that matches your hardware, then choose the
**edition** that matches how you intend to use the system.

----

Choosing an Architecture
------------------------

The architecture must match your target device. Boot files differ between the
two, so a 32-bit image will not boot a 64-bit-only target and vice versa.

- **ARM 32-bit (**\ ``armhf``\ **)** — the default. Includes boot files for the
  Zynq, Arria10, and Cyclone5 platforms (ZedBoard, ZC706, DE10-Nano, etc.) as
  well as Raspberry Pi.
- **ARM 64-bit (**\ ``arm64``\ **)** — includes boot files for the ZynqMP and
  Versal platforms (ZCU102, ADRV9009-ZU11EG, Jupiter SDR, VCK190, etc.) as well
  as Raspberry Pi.

For the full architecture-to-hardware mapping, see the boot files configuration
in the :doc:`Configuration <configuration>` section.

----

Choosing an Edition
-------------------

.. _releases-basic-image:

Basic Edition
~~~~~~~~~~~~~

The Basic edition is the minimal, default Kuiper image. It contains only the
essential packages and configuration needed for a functional system, plus the
boot files for its architecture. It has **no desktop environment and no ADI
libraries or tools**.

It is built from the default :doc:`config file <configuration>`, with the
architecture and boot-file options set to match the variant:

- **ARM 32-bit Basic** — ``TARGET_ARCHITECTURE=armhf`` with the ``armhf`` boot
  files (Zynq, Arria10, Cyclone5, Raspberry Pi).
- **ARM 64-bit Basic** — ``TARGET_ARCHITECTURE=arm64`` with the ``arm64`` boot
  files (ZynqMP, Versal, Raspberry Pi).

**Perfect for:** headless applications, a foundation for custom development, and
resource-constrained environments.

.. _releases-full-image:

Full Edition
~~~~~~~~~~~~

The Full edition includes everything in the Basic edition plus the complete ADI
software stack and a graphical environment:

- XFCE desktop environment with VNC server (``CONFIG_DESKTOP=y``)
- The full ADI library suite (libiio, pyadi-iio, libm2k, libad9361, libad9166)
- ADI applications (IIO Oscilloscope, Scopy) and GNU Radio
- Additional development tools and utilities

This corresponds to the :doc:`config file <configuration>` with all optional
components enabled, built for the variant's architecture.

**Perfect for:** complete development workstations, evaluation and testing, and
learning the ADI ecosystem.

.. tip::

   Need a different combination of components — say Basic plus one or two
   specific libraries? Build a :ref:`custom image <quick-start>` instead of
   using a release. See the :doc:`Configuration <configuration>` section.

----

Included Components
-------------------

The tables below list the main components that make up a release: the version
shipped, the config option that controls it, and the Debian package it is
installed from. Use the config option name to enable or disable the component
in a :ref:`custom build <quick-start>`.

.. note::

   Versions reflect the components at the time of writing and may differ
   between releases. The exact versions built into your image are recorded in
   ``/config`` and in ``/etc/kuiper-packages`` (the installed package versions),
   and can also be listed on the device with ``dpkg -l``.

System and Boot Components
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Present in every edition. The boot files installed depend on the architecture
and on the boot options selected (see :doc:`Configuration <configuration>`).

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Component
     - Architecture
     - Config option
     - Debian package
   * - ADI Linux kernel
     - armhf, arm64
     - (always included)
     - built from the ADI Linux tree
   * - ADI Raspberry Pi kernel (6.12)
     - armhf, arm64
     - ``CONFIG_RPI_BOOT_FILES``
     - ``adi-rpi-boot``
   * - ADI system utilities and scripts
     - all
     - (always included)
     - ``adi-scripts``
   * - Zynq boot files
     - armhf
     - ``CONFIG_ARCH_ZYNQ``
     - ``adi-zynq-boot``
   * - Arria10 boot files
     - armhf
     - ``CONFIG_ARCH_ARRIA10``
     - ``adi-arria10-boot``
   * - Cyclone5 boot files
     - armhf
     - ``CONFIG_ARCH_CYCLONE5``
     - ``adi-cyclone5-boot``
   * - ZynqMP boot files
     - arm64
     - ``CONFIG_ARCH_ZYNQMP``
     - ``adi-zynqmp-boot``
   * - Versal boot files
     - arm64
     - ``CONFIG_ARCH_VERSAL``
     - ``adi-versal-boot``

.. note::

   The Intel/Xilinx boot file packages bundle the U-Boot and ARM Trusted
   Firmware binaries required to boot those platforms.

ADI Libraries (Full Edition)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Component
     - Version
     - Config option
     - Debian package
   * - libiio
     - v0.26
     - ``CONFIG_LIBIIO``
     - ``libiio`` (from the Debian/Ubuntu upstream)
   * - pyadi-iio
     - v0.0.20
     - ``CONFIG_PYADI``
     - ``pyadi-iio`` (pip package)
   * - libm2k
     - v0.9.0
     - ``CONFIG_LIBM2K``
     - ``libm2k``
   * - libad9166-iio
     - v0.3.0
     - ``CONFIG_LIBAD9166_IIO``
     - ``libad9166``
   * - libad9361-iio
     - v0.4.0
     - ``CONFIG_LIBAD9361_IIO``
     - ``libad9361``

ADI Applications (Full Edition)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Component
     - Version
     - Config option
     - Debian package
   * - IIO Oscilloscope
     - v0.18.1
     - ``CONFIG_IIO_OSCILLOSCOPE``
     - ``iio-oscilloscope``
   * - IIO FM Radio
     - v0.3.0
     - ``CONFIG_IIO_FM_RADIO``
     - ``iio-fm-radio``
   * - FRU Tools
     - v0.8.1.7
     - ``CONFIG_FRU_TOOLS``
     - ``fru-tools``
   * - JESD Eye Scan GTK
     - v0.2
     - ``CONFIG_JESD_EYE_SCAN_GTK``
     - ``jesd-eye-scan-gtk``
   * - Colorimeter
     - v0.3.0
     - ``CONFIG_COLORIMETER``
     - ``colorimeter``
   * - Scopy
     - v2.2.0
     - ``CONFIG_SCOPY``
     - ``scopy``
   * - gr-m2k
     - v1.0.0
     - ``CONFIG_GRM2K``
     - ``gr-m2k``
   * - GNU Radio
     - Debian repository version
     - ``CONFIG_GNURADIO``
     - ``gnuradio`` (from the Debian repository)

Desktop Environment (Full Edition)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The Full edition also installs the XFCE desktop environment and an X11VNC
server for remote graphical access, controlled by ``CONFIG_DESKTOP``. See
:ref:`VNC Access <use-kuiper-image-vnc>` for how to connect.

----

Building Beyond the Releases
----------------------------

The releases cover the two most common setups, Basic and Full. To pick an
arbitrary subset of the components above, or to add options not included in any
release, build a :ref:`custom image <quick-start>`. Some options only available
when building your own image include:

- **Source code export** (``EXPORT_SOURCES``) — collect the source of every
  package in the image.
- **Custom scripts** (``EXTRA_SCRIPT``) — run your own script during the build.
  See :doc:`Custom Script Integration <customization>`.
- **Raspberry Pi packages** (``INSTALL_RPI_PACKAGES``) — add ``raspi-config``,
  GPIO tooling, and other Raspberry Pi specific packages.

See the :doc:`Configuration <configuration>` section for the full list of
options.

----

.. _supported-projects:

Supported Projects
------------------

The table below lists all ADI evaluation board and carrier board combinations
supported in the current release. The **Architecture** column shows which
Kuiper image variant (32-bit or 64-bit) is required.

.. list-table::
   :header-rows: 1
   :class: bold-header
   :widths: 40 25 20

   * - Project
     - Carrier
     - Architecture
   * - ad353xr
     - coraz7s
     - zynq
   * - ad353xr
     - de10nano
     - cyclone5
   * - ad353xr
     - zed
     - zynq
   * - ad35xxr_evb
     - zed
     - zynq
   * - ad4052_ardz
     - coraz7s
     - zynq
   * - ad4052_ardz
     - de10nano
     - cyclone5
   * - ad4062_ardz
     - coraz7s
     - zynq
   * - ad4062_ardz
     - de10nano
     - cyclone5
   * - ad4080_fmc_evb
     - zed
     - zynq
   * - ad4110
     - zed
     - zynq
   * - ad411x_ad717x
     - de10nano
     - cyclone5
   * - ad4134_fmc
     - zed
     - zynq
   * - ad4170_asdz
     - coraz7s
     - zynq
   * - ad4170_asdz
     - de10nano
     - cyclone5
   * - ad4630_fmc
     - zed
     - zynq
   * - ad469x_evb
     - coraz7s
     - zynq
   * - ad469x_evb
     - de10nano
     - cyclone5
   * - ad469x_evb
     - zed
     - zynq
   * - ad485x_fmcz
     - zed
     - zynq
   * - ad4880_fmc_evb
     - zed
     - zynq
   * - ad5758_sdz
     - zed
     - zynq
   * - ad5766_sdz
     - zed
     - zynq
   * - ad57xx_ardz
     - coraz7s
     - zynq
   * - ad57xx_ardz
     - de10nano
     - cyclone5
   * - ad6676evb
     - zc706
     - zynq
   * - ad7124_asdz
     - de10nano
     - cyclone5
   * - ad7134_fmc
     - zed
     - zynq
   * - ad719x_asdz
     - coraz7s
     - zynq
   * - ad719x_asdz
     - de10nano
     - cyclone5
   * - ad738x_fmc
     - zed
     - zynq
   * - ad7405_fmc
     - zed
     - zynq
   * - ad7606x_fmc
     - zed
     - zynq
   * - ad7616_sdz
     - zed
     - zynq
   * - ad77681evb
     - zed
     - zynq
   * - ad7768evb
     - zed
     - zynq
   * - ad777x_fmcz
     - zed
     - zynq
   * - ad9081_fmca_ebz
     - a10soc
     - arria10
   * - ad9081_fmca_ebz
     - fm87
     - versal
   * - ad9081_fmca_ebz
     - s10soc
     - stratix10
   * - ad9081_fmca_ebz
     - vck190
     - versal
   * - ad9081_fmca_ebz
     - vpk180
     - versal
   * - ad9081_fmca_ebz
     - zc706
     - zynq
   * - ad9081_fmca_ebz
     - zcu102
     - zynqmp
   * - ad9081_fmca_ebz_x_band
     - zcu102
     - zynqmp
   * - ad9082_fmca_ebz
     - vck190
     - versal
   * - ad9082_fmca_ebz
     - vpk180
     - versal
   * - ad9082_fmca_ebz
     - zc706
     - zynq
   * - ad9082_fmca_ebz
     - zcu102
     - zynqmp
   * - ad9083_evb
     - a10soc
     - arria10
   * - ad9083_evb
     - zcu102
     - zynqmp
   * - ad9084_ebz
     - fm87
     - versal
   * - ad9084_ebz
     - vck190
     - versal
   * - ad9084_ebz
     - vpk180
     - versal
   * - ad916x_fmc
     - zcu102
     - zynqmp
   * - ad9208_dual_ebz
     - s10soc
     - stratix10
   * - ad9209_fmca_ebz
     - vck190
     - versal
   * - ad9213_dual_ebz
     - s10soc
     - stratix10
   * - ad9265_fmc
     - zc706
     - zynq
   * - ad9265_fmc
     - zed
     - zynq
   * - ad9434_fmc
     - zc706
     - zynq
   * - ad9434_fmc
     - zed
     - zynq
   * - ad9467_fmc
     - zcu102
     - zynqmp
   * - ad9467_fmc
     - zed
     - zynq
   * - ad9656_fmc
     - zcu102
     - zynqmp
   * - ad9694_fmc
     - zcu102
     - zynqmp
   * - ad9695_fmc
     - zcu102
     - zynqmp
   * - ad9783_ebz
     - zcu102
     - zynqmp
   * - ad_gmsl2eth_sl
     - k26
     - zynqmp
   * - ad_quadmxfe1_ebz
     - s10soc
     - stratix10
   * - ada4355_fmc
     - zed
     - zynq
   * - adaq23875
     - zed
     - zynq
   * - adaq7980_sdz
     - zed
     - zynq
   * - adaq8092_fmc
     - zed
     - zynq
   * - admx100x_evb
     - zcu102
     - zynqmp
   * - admx6001_ebz
     - zcu102
     - zynqmp
   * - adrv9001
     - a10soc
     - arria10
   * - adrv9001
     - zcu102
     - zynqmp
   * - adrv9001
     - zed
     - zynq
   * - adrv9001_dual
     - zcu102
     - zynqmp
   * - adrv9009
     - a10soc
     - arria10
   * - adrv9009
     - zc706
     - zynq
   * - adrv9009
     - zcu102
     - zynqmp
   * - adrv9026
     - zcu102
     - zynqmp
   * - adrv903x
     - vck190
     - versal
   * - adrv903x
     - zcu102
     - zynqmp
   * - adrv904x
     - vck190
     - versal
   * - adrv904x
     - zcu102
     - zynqmp
   * - adrv9371x
     - a10soc
     - arria10
   * - adrv9371x
     - zc706
     - zynq
   * - adrv9371x
     - zcu102
     - zynqmp
   * - adv7511
     - zc702
     - zynq
   * - adv7511
     - zc706
     - zynq
   * - adv7511
     - zed
     - zynq
   * - adv7513
     - de10nano
     - cyclone5
   * - arradio
     - c5soc
     - cyclone5
   * - cn0363
     - zed
     - zynq
   * - cn0506
     - zed
     - zynq
   * - cn0540
     - coraz7s
     - zynq
   * - cn0540
     - de10nano
     - cyclone5
   * - cn0561
     - de10nano
     - cyclone5
   * - cn0577
     - zed
     - zynq
   * - cn0579
     - zed
     - zynq
   * - cn0585
     - zed
     - zynq
   * - dac_fmc_ebz
     - a10soc
     - arria10
   * - dac_fmc_ebz
     - zc706
     - zynq
   * - dac_fmc_ebz
     - zcu102
     - zynqmp
   * - daq2
     - a10soc
     - arria10
   * - daq2
     - zc706
     - zynq
   * - daq2
     - zcu102
     - zynqmp
   * - daq3
     - zc706
     - zynq
   * - daq3
     - zcu102
     - zynqmp
   * - dc2677a
     - zed
     - zynq
   * - fmcomms11
     - zc706
     - zynq
   * - fmcomms8
     - zcu102
     - zynqmp
   * - jupiter_sdr
     - zcu102
     - zynqmp
   * - max96724
     - zed
     - zynq
   * - pulsar_adc
     - coraz7s
     - zynq
   * - pulsar_adc
     - de10nano
     - cyclone5
   * - pulsar_adc
     - zed
     - zynq
   * - pulsar_lvds_adc
     - zed
     - zynq
