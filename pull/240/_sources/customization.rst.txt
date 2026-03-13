.. _customization:

Custom Script Integration
=========================

Kuiper allows you to run additional scripts during the build process to 
customize the resulting image. This feature enables advanced customization 
beyond the standard configuration options.

----

Using the Example Script
------------------------

To use the provided example script:

1. In the ``config`` file, set the ``EXTRA_SCRIPT`` variable to:

   .. code-block:: bash

      EXTRA_SCRIPT=stages/07.extra-tweaks/01.extra-scripts/examples/extra-script-example.sh

2. If you need to pass ``config`` file parameters to the script, uncomment 
   the line where it sources the config file in the example script.

3. Add your custom commands to the example script file.

----

Using Your Own Custom Script
----------------------------

To use your own custom script:

1. Place your script file inside the ``adi-kuiper-gen/stages`` directory.

2. In the ``config`` file, set the ``EXTRA_SCRIPT`` variable to the path of 
   your script relative to the ``adi-kuiper-gen`` directory.

3. Make sure your script is executable (``chmod +x your-script.sh``).

Custom scripts are executed in the chroot environment of the target system 
during the build process, allowing you to install additional packages, modify 
system files, or perform any other customization.
