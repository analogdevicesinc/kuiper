.. _build-flow:

Build Flow
==========

The Kuiper build process uses Docker to create a controlled environment for 
building Debian-based images for Analog Devices products. The build follows 
these high-level steps:

1. ``build-docker.sh`` creates a Docker container with all necessary build 
   dependencies
2. Inside the container, ``kuiper-stages.sh`` orchestrates a series of build 
   stages
3. Each stage performs specific tasks like system configuration, tool 
   installation, and boot setup
4. The final image is exported as a zip file to the ``kuiper-volume`` 
   directory on your host machine

This approach ensures consistent builds across different host systems while 
allowing full customization through the ``config`` file.

The ``config`` file is first read by ``build-docker.sh`` on the host system 
to set up environment variables and Docker options. It is then copied into 
the container where ``kuiper-stages.sh`` reads it again to determine which 
stages to execute and how to configure them.

.. svg:: sources/build_flow.svg
   :align: center

----

Docker Build Environment
------------------------

Docker is used to perform the build inside a container, which partially 
isolates the build from the host system. This allows the script to work on 
non-Debian based systems (e.g., Fedora Linux). The isolation is not total 
due to the need to use some kernel-level services for ARM emulation (binfmt) 
and loop devices (losetup).

The ``build-docker.sh`` script handles:

- Checking prerequisites and permissions
- Building a Docker image with all necessary dependencies
- Running a Docker container with appropriate options
- Mounting volumes to share data between the host and container
- Setting environment variables based on the ``config`` file
- Starting the internal build process by calling ``kuiper-stages.sh``
- Cleaning up the container after completion (if ``PRESERVE_CONTAINER=n``)

Running the Build
~~~~~~~~~~~~~~~~~

To build:

.. code-block:: bash

   sudo ./build-docker.sh

Your Kuiper image will be in the ``kuiper-volume/`` folder inside the cloned 
repository on your machine as a zip file named 
``image_YYYY-MM-DD-ADI-Kuiper-Linux-[arch].zip``. After successful build, 
the Docker image and the build container are removed if 
``PRESERVE_CONTAINER=n``.

If needed, you can remove the build container with:

.. code-block:: bash

   docker rm -v debian_<DEBIAN_VERSION>_rootfs_container

If you choose to preserve the Docker container, you can access the Kuiper 
root filesystem by copying it from the container to your machine with this 
command:

.. code-block:: bash

   CONTAINER_ID=$(docker inspect --format="{{.Id}}" debian_<DEBIAN_VERSION>_rootfs_container)
   sudo docker cp $CONTAINER_ID:<TARGET_ARCHITECTURE>_rootfs .

You need to replace ``<DEBIAN_VERSION>`` and ``<TARGET_ARCHITECTURE>`` with 
the ones in the configuration file.

Example:

.. code-block:: bash

   CONTAINER_ID=$(docker inspect --format="{{.Id}}" debian_bookworm_rootfs_container)
   sudo docker cp $CONTAINER_ID:armhf_rootfs .

Docker Container Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When the Docker container is run, various required command line arguments 
are provided:

- ``-t``: Allocates a pseudo-TTY allowing interaction with container's shell
- ``--privileged``: Provides elevated privileges required by the chroot 
  command
- ``-v /dev:/dev``: Mounts the host system's device directory
- ``-v /lib/modules:/lib/modules``: Mounts kernel modules from the host
- ``-v ./kuiper-volume:/kuiper-volume``: Creates a shared volume for the 
  output
- ``-e "DEBIAN_VERSION={value}"``: Sets environment variables from the config 
  file

The ``--name`` and ``--privileged`` options are already set by the script and 
should not be redefined.

----

Stage-Based Build Process
-------------------------

Inside the Docker container, ``kuiper-stages.sh`` orchestrates the entire 
build process. This script reads the ``config`` file, sets up environment 
variables, and executes a series of stages in a specific order.

How Stages Are Processed
~~~~~~~~~~~~~~~~~~~~~~~~

The build process follows these steps inside the Docker container:

1. ``kuiper-stages.sh`` loops through the ``stages`` directory in 
   alphanumeric order
2. Within each stage, it processes subdirectories in alphanumeric order
3. For each subdirectory, it runs the following files if they exist:

   - ``run.sh`` - A shell script executed in the Docker container's context
   - ``run-chroot.sh`` - A shell script executed within the Kuiper image 
     using chroot
   - Package installation files:

     - ``packages-[*]`` - Lists packages to install with 
       ``--no-install-recommends``
     - ``packages-[*]-with-recommends`` - Lists packages to install with 
       their recommended dependencies

The package installation files (``packages-[*]``) are processed if the 
corresponding configuration option is enabled. For example, 
``packages-desktop`` is only processed if ``CONFIG_DESKTOP=y`` in the config 
file.

Key Stages Overview
~~~~~~~~~~~~~~~~~~~

The build process is divided into several stages for logical clarity and 
modularity:

- **01.bootstrap** - Creates a usable filesystem using ``debootstrap``
- **02.set-locale-and-timezone** - Configures system locale and timezone 
  settings
- **03.system-tweaks** - Sets up users, passwords, and system configuration
- **04.configure-desktop-env** - Installs and configures desktop environment 
  (if enabled)
- **05.adi-tools** - Installs Analog Devices libraries and tools (based on 
  config)
- **06.boot-partition** - Adds boot files for different platforms
- **07.extra-tweaks** - Applies custom scripts and additional configurations
- **08.export-stage** - Creates and exports the final image

Each stage contains multiple substages that handle specific aspects of the 
build process. The stages are designed to be modular, allowing for easy 
customization and extension.

For a more detailed description of each stage and its purpose, see the 
:doc:`Stage Reference <stage-reference>` section.

Stage Execution Logic
~~~~~~~~~~~~~~~~~~~~~

The ``kuiper-stages.sh`` script contains a helper function called 
``install_packages`` that handles package installation for each stage. This 
function:

1. Checks if package files exist for the current stage
2. Verifies if the corresponding configuration option is enabled
3. Installs the packages using the appropriate apt-get command

The script then executes each stage's ``run.sh`` script, which may perform 
additional configuration steps, compile software from source, or prepare 
files for the final image.

This modular approach allows users to easily customize the build process by 
modifying existing stages or adding new ones.
