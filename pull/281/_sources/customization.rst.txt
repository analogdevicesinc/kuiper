.. _customization:

Advanced Customization
======================

This guide covers advanced customization options for developers and advanced
users who need to extend the build process beyond standard configuration
options.

----

Custom Script Integration
--------------------------

Kuiper allows you to run additional scripts during the build process to
customize the resulting image. This feature enables advanced customization
beyond the standard configuration options.

Using the Example Script
~~~~~~~~~~~~~~~~~~~~~~~~

To use the provided example script:

1. In the ``config`` file, set the ``EXTRA_SCRIPT`` variable to:

   .. code-block:: bash

      EXTRA_SCRIPT=stages/07.extra-tweaks/01.extra-scripts/examples/extra-script-example.sh

2. If you need to pass ``config`` file parameters to the script, uncomment
   the line where it sources the config file in the example script.

3. Add your custom commands to the example script file.

Using Your Own Custom Script
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To use your own custom script:

1. Place your script file inside the ``kuiper/stages`` directory.

2. In the ``config`` file, set the ``EXTRA_SCRIPT`` variable to the path of 
   your script relative to the ``kuiper`` directory.

3. Make sure your script is executable (``chmod +x your-script.sh``).

Custom scripts are executed in the chroot environment of the target system
during the build process, allowing you to install additional packages, modify
system files, or perform any other customization.

----

Building from Source
--------------------

By default, ADI libraries are installed from Analog Devices' package
repository. For development, testing unreleased features, or custom builds,
you can build libraries from source by modifying the stage scripts.

How to Enable Source Builds
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Library installation is controlled by stage scripts in ``stages/05.adi-tools/``.
Each script has a ``USE_ADI_REPO`` variable that controls the installation
method:

- ``USE_ADI_REPO=y`` - Install from package repository (default)
- ``USE_ADI_REPO=n`` - Build from source using git

**Example: Building libiio from source**

Edit ``stages/05.adi-tools/01.install-libiio/run.sh`` and set:

.. code-block:: bash

   USE_ADI_REPO=n

You can also customize the git branch and CMake arguments:

.. code-block:: bash

   BRANCH_LIBIIO=libiio-v0
   CONFIG_LIBIIO_CMAKE_ARGS="-DWITH_HWMON=ON \
                             -DWITH_SERIAL_BACKEND=ON \
                             -DWITH_MAN=ON \
                             -DWITH_EXAMPLES=ON \
                             -DPYTHON_BINDINGS=ON \
                             -DCMAKE_BUILD_TYPE=Release \
                             -DCMAKE_COLOR_MAKEFILE=OFF \
                             -Bbuild -H."

The same pattern applies to other libraries (``libm2k``, ``libad9361-iio``,
``libad9166-iio``, etc.) and applications (``iio-oscilloscope``,
``jesd-eye-scan-gtk``, ``gr-m2k``, etc.). Each has corresponding ``BRANCH_``
and ``CMAKE_ARGS`` variables in their respective stage scripts.

Library Dependencies
~~~~~~~~~~~~~~~~~~~~

When building from source, dependencies must be satisfied. Enable required
dependencies in the ``config`` file:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Library/Application
     - Required Dependencies
   * - ``CONFIG_PYADI``
     - ``CONFIG_LIBIIO``
   * - ``CONFIG_LIBM2K``
     - ``CONFIG_LIBIIO``
   * - ``CONFIG_LIBAD9166_IIO``
     - ``CONFIG_LIBIIO``
   * - ``CONFIG_LIBAD9361_IIO``
     - ``CONFIG_LIBIIO``
   * - ``CONFIG_IIO_OSCILLOSCOPE``
     - ``CONFIG_LIBIIO``, ``CONFIG_LIBAD9166_IIO``, ``CONFIG_LIBAD9361_IIO``
   * - ``CONFIG_COLORIMETER``
     - ``CONFIG_LIBIIO``
   * - ``CONFIG_JESD_EYE_SCAN_GTK``
     - ``CONFIG_LIBIIO``
   * - ``CONFIG_GRM2K``
     - ``CONFIG_LIBIIO``, ``CONFIG_LIBM2K``, ``CONFIG_GNURADIO``

.. note::

   Dependencies are handled automatically when using package installation
   (the default). Manual dependency management is only needed when building
   from source.
