.. _quick-start:

Quick Start
===========

This guide will help you get a Kuiper image quickly, either by downloading 
a pre-built image or building your own with custom settings.

----

Choose Your Path
----------------

**Option A: Download Pre-built Image (5 minutes)**
   Get a ready-to-use basic Kuiper image immediately:

   - Download the latest build from :git-adi-kuiper-gen:`GitHub Actions 
     <actions/workflows/kuiper2_0-build.yml?query=branch:main+>`
   - Skip to :doc:`Using Kuiper Images <use-kuiper-image>` to write it to an 
     SD card

**Option B: Build Custom Image (30-60 minutes)**
   Build your own image with specific configurations:

   - Follow the build process below for full customization
   - Configure exactly what tools and features you need

----

Building Your Own Image
-----------------------

If you chose Option B above, follow these steps to build a custom Kuiper 
image:

Clone the Repository
~~~~~~~~~~~~~~~~~~~~

After ensuring your build environment meets the :doc:`prerequisites 
<prerequisites>`, clone the repository:

.. code-block:: bash

   git clone --depth 1 https://github.com/analogdevicesinc/adi-kuiper-gen
   cd adi-kuiper-gen

Review Default Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The default configuration will build a basic 32-bit (armhf) Debian Bookworm 
image with Raspberry Pi boot files. For most users, this is sufficient to get 
started:

- Target architecture: ``armhf`` (32-bit)
- Debian version: ``bookworm``
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
~~~~~~~~~~~~~~~

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
~~~~~~~~~~~~~~~~~

After a successful build, your Kuiper image will be available as a zip file 
in the ``kuiper-volume/`` directory within the repository. The filename will 
follow the pattern ``image_YYYY-MM-DD-ADI-Kuiper-Linux-[arch].zip``.

----

Using the Kuiper Image
----------------------

Now that you obtained a bootable image, you can follow the steps in :doc:`Using 
Kuiper Images <use-kuiper-image>` section in order to write the image to an SD 
card and boot your device.
