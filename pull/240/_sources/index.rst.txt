ADI Kuiper Linux
================

.. description::

   ADI Kuiper Linux - A specialized Debian distribution for Analog Devices 
   hardware with pre-configured libraries, tools, and applications for 
   seamless development

Kuiper is a specialized Debian-based Linux distribution designed specifically 
for Analog Devices hardware and evaluation boards. It provides a complete, 
ready-to-use environment with ADI libraries, tools, and applications 
pre-configured for seamless hardware integration.

Whether you're prototyping with an ADI evaluation board, developing embedded 
applications, or building software-defined radio solutions, Kuiper gives you 
a solid foundation to start immediately without the complexity of manual 
system configuration.

----

Quick Start
-----------

Get up and running with Kuiper:

#. :doc:`Check prerequisites <prerequisites>` (Ubuntu 22.04 + Docker for 
   building)
#. Get Kuiper image:

   - **Quick option**: Download pre-built from :git-adi-kuiper-gen:`GitHub 
     Actions <actions/workflows/kuiper2_0-build.yml?query=branch:main+>`
   - **Custom option**: Clone repository and build your own

   .. code-block:: bash

      git clone --depth 1 https://github.com/analogdevicesinc/adi-kuiper-gen
      cd adi-kuiper-gen
      sudo ./build-docker.sh

   For detailed instructions, see the :doc:`Quick Start <quick-start>` section.

#. :doc:`Write the image to an SD card and boot your device <use-kuiper-image>`

----

What's Included
---------------

Kuiper provides a configurable development environment tailored for ADI 
hardware:

**Core System**
   Debian Bookworm base with optimized configurations for ARM devices

**ADI Libraries (Optional)**
   libiio, pyadi-iio, libm2k, libad9361, libad9166 for hardware communication

**Development Tools (Optional)**
   IIO Oscilloscope, Scopy, GNU Radio, and specialized ADI applications

**Hardware Support**
   Boot files and configurations for Raspberry Pi, Xilinx, and Intel platforms

**Desktop Environment (Optional)**
   XFCE desktop with VNC access for graphical applications

All optional components are configurable - build exactly what you need for your 
project.

----

Build Configurations
--------------------

Kuiper offers three main configurations to suit different needs. You can either 
download pre-built images or create custom builds using the configuration 
system.

For detailed stage breakdowns and component lists, see :doc:`Kuiper Versions 
<kuiper-versions>`.

Basic Image (Default)
~~~~~~~~~~~~~~~~~~~~~

**What's included:**

- Debian Bookworm base system with essential utilities
- Boot files for Raspberry Pi, Xilinx, and Intel platforms
- User account setup (analog/analog) with sudo access
- Network configuration and SSH access

**Perfect for:** Headless applications, foundation for custom development, 
resource-constrained environments

**Get it:** Download pre-built from :git-adi-kuiper-gen:`GitHub Actions 
<actions/workflows/kuiper2_0-build.yml?query=branch:main+>` or build using the
default config file.

Full Image
~~~~~~~~~~

**What's included:**

- Everything from Basic Image
- XFCE desktop environment with VNC server
- Complete ADI library suite (libiio, pyadi-iio, libm2k, libad9361, libad9166)
- ADI applications (IIO Oscilloscope, Scopy), GNU Radio
- Development tools and utilities

**Perfect for:** Complete development workstations, evaluation and testing, 
learning ADI ecosystem

**Get it:** Download pre-built from :git-adi-kuiper-gen:`GitHub Actions 
<actions/workflows/kuiper2_0-build.yml?query=branch:main+>` or enable all
options in the config file.

Custom Image
~~~~~~~~~~~~

**What's included:**

- Configurable combination of any available components
- Choose specific ADI libraries and tools for your needs
- Optional desktop environment and development packages
- Tailored boot configuration for your target hardware

**Perfect for:** Production deployments, specialized applications, specific 
tool combinations

**Get it:** Modify the :doc:`config file <configuration>` and run the build 
process locally.

----

Community and Support
---------------------

**Issues and Bug Reports**
   Report problems on :git-adi-kuiper-gen:`GitHub Issues <issues+>`

**Source Code**
   View and contribute at :git-adi-kuiper-gen:`/`

**ADI Community** 
   Connect with other developers at :ez:`linux-software-drivers`

----

Documentation
=============

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   prerequisites
   quick-start
   use-kuiper-image
   hardware-configuration

.. toctree::
   :maxdepth: 2
   :caption: Configuration & Building

   configuration
   kuiper-versions
   build-flow

.. toctree::
   :maxdepth: 2
   :caption: Advanced Topics

   stage-reference
   customization
   repositories

.. toctree::
   :maxdepth: 2
   :caption: Reference

   troubleshooting
