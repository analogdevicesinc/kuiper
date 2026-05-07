.. _troubleshooting:

Troubleshooting
===============

----

Cross-Architecture Build Issues
-------------------------------

If you encounter errors related to ARM emulation, first ensure you've properly
set up the prerequisites as described in the
:doc:`Prerequisites section <prerequisites>`.

Common error messages and their solutions:

.. code-block:: text

   W: Failure trying to run: chroot chroot "//armhf_rootfs" /bin/true

OR

.. code-block:: text

   chroot: failed to run command '/bin/true': Exec format error

**Solution**:

The build script automatically registers QEMU emulation handlers when building
on x86 systems. If you encounter the errors above:

1. Ensure the required packages are installed:

   .. code-block:: bash

      sudo apt-get install qemu-user-binfmt binfmt-support




2. Make sure you're running the build script with ``sudo`` to allow Docker
   privileged access for automatic QEMU registration.

4. If the automatic registration fails, you can manually register QEMU handlers:

   .. code-block:: bash

      docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

----

Docker Permission Issues
------------------------

If you encounter permission errors when running Docker commands:

.. code-block:: bash

   permission denied while trying to connect to the Docker daemon socket

**Solution**:

1. Either prefix commands with ``sudo`` as shown in the build instructions

2. Or add your user to the docker group (requires logout/login):

   .. code-block:: bash

      sudo usermod -aG docker $USER

----

Build Path Issues
-----------------

If the build fails with debootstrap errors, check if your path contains spaces. 
As mentioned in the prerequisites, the build path must not contain spaces.

----

Other Issues
------------

For other issues not covered here, please check the 
:git-kuiper:`GitHub Issues <issues+>`
page or open a new issue with details about your problem.
