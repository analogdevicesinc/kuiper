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

     - ``qemu-user-binfmt``: For emulating ARM architecture
     - ``binfmt-support``: To enable execution of binaries from different
       architectures

   You can install them on Debian/Ubuntu with:

   .. code-block:: bash

      sudo apt-get update
      sudo apt-get install qemu-user-binfmt binfmt-support

   **Note**: The build script automatically registers QEMU emulation handlers
   when building ARM images on x86 systems. This requires Docker to run with
   privileged access (using ``sudo`` as shown in the build instructions).
