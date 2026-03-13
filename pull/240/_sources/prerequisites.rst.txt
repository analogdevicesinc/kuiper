.. _prerequisites:

Prerequisites
==============

----

Build Environment
-----------------

- **Operating System**: Ubuntu 22.04 LTS is recommended. Other Linux 
  distributions or versions may not work as expected.
- **Important**: Windows is not supported.
- **Space Requirements**: At least 10GB of free disk space for building images.
- **Note**: Ensure you clone this repository to a path **without spaces**. 
  Paths with spaces are not supported by debootstrap.

----

Required Software
-----------------

1. **Docker**:

   - Docker version 24.0.6 or compatible is required to build Kuiper images.
   - If you don't have Docker installed, follow the installation steps at: 
     https://docs.docker.com/engine/install/

2. **Cross-Architecture Support**:

   - These packages are necessary to build ARM-based images on x86 systems:

     - ``qemu-user-static``: For emulating ARM architecture
     - ``binfmt_misc``: Kernel module to run binaries from different 
       architectures

   You can install them on Debian/Ubuntu with:

   .. code-block:: bash

      sudo apt-get update
      sudo apt-get install qemu-user-static binfmt-support

   To ensure the binfmt_misc module is loaded:

   .. code-block:: bash

      sudo modprobe binfmt_misc

   If using WSL, you may need to enable the service:

   .. code-block:: bash

      sudo update-binfmts --enable
