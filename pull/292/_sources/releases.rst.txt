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

The table below lists every ADI evaluation board and carrier combination
supported in the current release, together with the FPGA vendor platform, the
boot-file Debian package it needs, and the Kuiper image architecture to use:

- **Eval Board** — the ADI evaluation board project.
- **Carrier** — the carrier or development board it is built for.
- **Platform** — the FPGA vendor toolchain, ``xilinx`` or ``intel``.
- **Debian Package** — the boot-file platform, which selects the matching
  ``adi-<platform>-boot`` package (for example ``zynq`` is installed from
  ``adi-zynq-boot``). See :doc:`Package Management <package-management>`.
- **Architecture** — the Kuiper image variant required: ``armhf`` (32-bit) or
  ``arm64`` (64-bit).

.. list-table::
   :header-rows: 1
   :class: bold-header
   :widths: 30 22 12 18 15

   * - Eval Board
     - Carrier
     - Platform
     - Debian Package
     - Architecture
   * - ad4000
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad4001
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad4002
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad4003
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad4020
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad403x
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad4630_fmc
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad469x_evb
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad6676evb
     - zc706
     - xilinx
     - zynq
     - armhf
   * - ad7383_4
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad738x_fmc
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad7768
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad7768-4
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad77681_evb
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad7984
     - coraz7s
     - xilinx
     - zynq
     - armhf
   * - ad9081
     - zc706
     - xilinx
     - zynq
     - armhf
   * - ad9081_np12
     - zc706
     - xilinx
     - zynq
     - armhf
   * - ad9082
     - zc706
     - xilinx
     - zynq
     - armhf
   * - ad9172_fmc
     - zc706
     - xilinx
     - zynq
     - armhf
   * - ad9265-fmc-125ebz
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad9434-fmc
     - zc706
     - xilinx
     - zynq
     - armhf
   * - ad9434-fmc
     - zed
     - xilinx
     - zynq
     - armhf
   * - ad9467-fmc
     - zed
     - xilinx
     - zynq
     - armhf
   * - adaq4003
     - coraz7s
     - xilinx
     - zynq
     - armhf
   * - adaq4003
     - zed
     - xilinx
     - zynq
     - armhf
   * - adaq4224-24
     - zed
     - xilinx
     - zynq
     - armhf
   * - adaq8092
     - zed
     - xilinx
     - zynq
     - armhf
   * - adrv9002
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adrv9002
     - zed
     - xilinx
     - zynq
     - armhf
   * - adrv9002_rx2tx2
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adrv9002_rx2tx2
     - zed
     - xilinx
     - zynq
     - armhf
   * - adrv9008-1
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adrv9008-2
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adrv9009
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adrv9361z7035_cmos
     - ccbob
     - xilinx
     - zynq
     - armhf
   * - adrv9361z7035_lvds
     - ccbob
     - xilinx
     - zynq
     - armhf
   * - adrv9361z7035_lvds
     - ccfmc
     - xilinx
     - zynq
     - armhf
   * - adrv9364z7020_cmos
     - ccbob
     - xilinx
     - zynq
     - armhf
   * - adrv9364z7020_lvds
     - ccbob
     - xilinx
     - zynq
     - armhf
   * - adrv9371
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adrv9375
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adv7511
     - zc702
     - xilinx
     - zynq
     - armhf
   * - adv7511
     - zc706
     - xilinx
     - zynq
     - armhf
   * - adv7511
     - zed
     - xilinx
     - zynq
     - armhf
   * - adv7511_without_bitstream
     - zed
     - xilinx
     - zynq
     - armhf
   * - cn0363
     - zed
     - xilinx
     - zynq
     - armhf
   * - cn0506
     - socdk
     - intel
     - arria10
     - armhf
   * - cn0506_mii
     - zc706
     - xilinx
     - zynq
     - armhf
   * - cn0506_mii
     - zed
     - xilinx
     - zynq
     - armhf
   * - cn0506_rgmii
     - zc706
     - xilinx
     - zynq
     - armhf
   * - cn0506_rgmii
     - zed
     - xilinx
     - zynq
     - armhf
   * - cn0506_rmii
     - zc706
     - xilinx
     - zynq
     - armhf
   * - cn0506_rmii
     - zed
     - xilinx
     - zynq
     - armhf
   * - cn0540
     - coraz7s
     - xilinx
     - zynq
     - armhf
   * - cn0540
     - de10nano
     - intel
     - cyclone5
     - armhf
   * - cn0577
     - zed
     - xilinx
     - zynq
     - armhf
   * - cn0579
     - coraz7s
     - xilinx
     - zynq
     - armhf
   * - cn0579
     - de10nano
     - intel
     - cyclone5
     - armhf
   * - daq2
     - zc706
     - xilinx
     - zynq
     - armhf
   * - daq3
     - zc706
     - xilinx
     - zynq
     - armhf
   * - fmcomms11
     - zc706
     - xilinx
     - zynq
     - armhf
   * - fmcomms2
     - zc702
     - xilinx
     - zynq
     - armhf
   * - fmcomms2
     - zc706
     - xilinx
     - zynq
     - armhf
   * - fmcomms2
     - zed
     - xilinx
     - zynq
     - armhf
   * - fmcomms3
     - zc702
     - xilinx
     - zynq
     - armhf
   * - fmcomms3
     - zc706
     - xilinx
     - zynq
     - armhf
   * - fmcomms3
     - zed
     - xilinx
     - zynq
     - armhf
   * - fmcomms4
     - zc702
     - xilinx
     - zynq
     - armhf
   * - fmcomms4
     - zc706
     - xilinx
     - zynq
     - armhf
   * - fmcomms4
     - zed
     - xilinx
     - zynq
     - armhf
   * - fmcomms5
     - zc702
     - xilinx
     - zynq
     - armhf
   * - fmcomms5
     - zc706
     - xilinx
     - zynq
     - armhf
   * - fmcomms5-ext-lo-adf5355
     - zc706
     - xilinx
     - zynq
     - armhf
   * - fmcomms8
     - socdk
     - intel
     - arria10
     - armhf
   * - sockit_arradio
     - sockit
     - intel
     - cyclone5
     - armhf
   * - sockit_dc2677a
     - sockit
     - intel
     - cyclone5
     - armhf
   * - ad9081
     - vck190
     - xilinx
     - versal
     - arm64
   * - ad9081
     - vpk180
     - xilinx
     - versal
     - arm64
   * - ad9081_204b_txmode9_rxmode4
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9081_204c_txmode0_rxmode1
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9081_204c_txmode22_rxmode23
     - vck190
     - xilinx
     - versal
     - arm64
   * - ad9081_204c_txmode23_rxmode25
     - vck190
     - xilinx
     - versal
     - arm64
   * - ad9081_m4_l8
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9081_m8_l4
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9081_m8_l4_overlay
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9081_m8_l4_qpllrx
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9081_m8_l4_tdd
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9081_m8_l4_vcxo122p88
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9082
     - vck190
     - xilinx
     - versal
     - arm64
   * - ad9082
     - vpk180
     - xilinx
     - versal
     - arm64
   * - ad9082_204c_txmode22_rxmode23
     - vck190
     - xilinx
     - versal
     - arm64
   * - ad9082_m1_l8
     - vpk180
     - xilinx
     - versal
     - arm64
   * - ad9082_m4_l8
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9083
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9084
     - vck190
     - xilinx
     - versal
     - arm64
   * - ad9084
     - vpk180
     - xilinx
     - versal
     - arm64
   * - ad9084_m4_l1
     - vpk180
     - xilinx
     - versal
     - arm64
   * - ad9144
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9154
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9172_mode4
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9209
     - vck190
     - xilinx
     - versal
     - arm64
   * - ad9467_fmc
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9695
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - ad9783
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9002_cmos
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9002_lvds
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9002_rx2tx2_cmos
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9002_rx2tx2_lvds
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9008-1
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9008-2
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9009
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9009zu11eg_adrv2crr
     - adrv9009zu11eg_adrv2crr
     - xilinx
     - zynqmp
     - arm64
   * - adrv9025
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9025_jesd204c
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9025_nls
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9371
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - adrv9375
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - cn0506_mii
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - cn0506_rgmii
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - cn0506_rmii
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - daq2
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - daq2_m4_l4
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - daq3
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms2
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms3
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms4
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms5
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms5_ext_lo_adf5355
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms8
     - adrv9009zu11eg_adrv2crr
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms8
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms8_multisom_primary
     - adrv9009zu11eg_adrv2crr
     - xilinx
     - zynqmp
     - arm64
   * - fmcomms8_multisom_secondary
     - adrv9009zu11eg_adrv2crr
     - xilinx
     - zynqmp
     - arm64
   * - jupiter_sdr
     - jupiter_sdr
     - xilinx
     - zynqmp
     - arm64
   * - jupiter_sdr_rx2tx2
     - jupiter_sdr
     - xilinx
     - zynqmp
     - arm64
   * - multisom-primary
     - adrv9009zu11eg_adrv2crr
     - xilinx
     - zynqmp
     - arm64
   * - multisom-secondary
     - adrv9009zu11eg_adrv2crr
     - xilinx
     - zynqmp
     - arm64
   * - stingray
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - stingray_direct_clk
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - stingray_vcxo100
     - zcu102
     - xilinx
     - zynqmp
     - arm64
   * - stingray_vcxo100_direct_clk
     - zcu102
     - xilinx
     - zynqmp
     - arm64
