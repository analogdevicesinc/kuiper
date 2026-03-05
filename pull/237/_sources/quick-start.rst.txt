.. _quick-start:

Quick Start
===========

This guide will help you get a Kuiper image. Choose from three options
depending on your needs: download a tested release, get the latest development
build, or create a custom build with your own configuration.

----

Getting a Kuiper Image
----------------------

Release Images (Recommended)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Best for**: Production use, evaluation, getting started quickly

**Time**: ~5 minutes (download only)

Download a tested and stable Kuiper release. Two versions are available:

- **Basic Image**: Minimal system with essential boot files, no desktop
  environment or ADI tools
- **Full Image**: Complete system with XFCE desktop, ADI libraries and
  applications, development tools

For detailed information about what's included in each version, see
:doc:`Kuiper Versions <kuiper-versions>`.

**Download**: `ADI Kuiper Releases <RELEASE_LINK_PLACEHOLDER>`_

After downloading, skip to :ref:`quick-start-next-steps`.

Latest Development Builds
~~~~~~~~~~~~~~~~~~~~~~~~~

**Best for**: Testing latest features, development work, early access

**Time**: ~5 minutes (download only)

Download the most recent automated builds from the main branch. These include
the latest changes and improvements but may have less testing than official
releases.

**Download**: :git-adi-kuiper-gen:`GitHub Actions
<actions/workflows/kuiper2_0-build.yml?query=branch:main+>`

After downloading, skip to :ref:`quick-start-next-steps`.

Build Custom Image
~~~~~~~~~~~~~~~~~~

**Best for**: Custom configurations, specific tool combinations, specialized
deployments

**Time**: 30-60 minutes (build time)

Build your own image with complete control over included components and
configuration.

Prerequisites
+++++++++++++

Ensure your build environment meets the :doc:`prerequisites <prerequisites>`
before starting:

- Ubuntu 22.04 LTS (recommended)
- Docker installed and configured
- At least 10GB free disk space
- Repository cloned to a path without spaces

Clone the Repository
++++++++++++++++++++

Clone the repository:

.. code-block:: bash

   git clone --depth 1 https://github.com/analogdevicesinc/adi-kuiper-gen
   cd adi-kuiper-gen

Review Default Configuration
+++++++++++++++++++++++++++++

The default configuration will build a basic 32-bit (armhf) Debian Trixie image
with Raspberry Pi boot files. For most users, this is sufficient to get started:

- Target architecture: ``armhf`` (32-bit)
- Debian version: ``trixie``
- Essential boot files included: Yes
- Desktop environment: No
- ADI tools: None (can be enabled as needed)

This configuration creates what we call the "Basic Image" that includes only
essential components. For details on exactly what stages and components are
included in this basic build, see :ref:`kuiper-versions-basic-image`.

For ADI evaluation boards, you can configure your target hardware now by
setting ``ADI_EVAL_BOARD`` and ``CARRIER`` in the config file, or configure
later after deployment. See :ref:`ADI Evaluation Boards Configuration
<hardware-configuration-adi-eval-boards>` for further information.

For customization options, see the :doc:`Configuration <configuration>`
section.

Build the Image
+++++++++++++++

Run the build script with sudo:

.. code-block:: bash

   sudo ./build-docker.sh

The build process will:

1. Create a Docker container with the necessary build environment
2. Set up a minimal Debian system
3. Configure system settings
4. Install selected components based on your configuration
5. Create a bootable image

This process typically takes 30-60 minutes depending on your system and
internet speed.

Locate the Output
+++++++++++++++++

After a successful build, your Kuiper image will be available as a zip file
in the ``kuiper-volume/`` directory within the repository. The filename will
follow the pattern ``image_YYYY-MM-DD-ADI-Kuiper-Linux-[arch].zip``.

----

.. _quick-start-next-steps:

Next Steps
----------

Now that you have a Kuiper image (from release, latest build, or custom build),
proceed to :doc:`Using Kuiper Images <use-kuiper-image>` to write the image to
an SD card and boot your device.
