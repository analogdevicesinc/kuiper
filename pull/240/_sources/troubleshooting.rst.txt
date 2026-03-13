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

   update-binfmts: warning: Couldn't load the binfmt_misc module.

OR

.. code-block:: text

   W: Failure trying to run: chroot chroot "//armhf_rootfs" /bin/true

OR

.. code-block:: text

   chroot: failed to run command '/bin/true': Exec format error

**Solution**:

1. Verify these specific files exist on your system:

   .. code-block:: bash

      /lib/modules/$(uname -r)/kernel/fs/binfmt_misc.ko
      /usr/bin/qemu-arm-static

2. If necessary, install the missing packages and load the module:

   .. code-block:: bash

      sudo apt-get install qemu-user-static binfmt-support
      sudo modprobe binfmt_misc

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
:git-adi-kuiper-gen:`GitHub Issues <issues+>`
page or open a new issue with details about your problem.
