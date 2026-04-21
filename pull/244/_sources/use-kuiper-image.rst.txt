.. _use-kuiper-image:

Using Kuiper Images
===================

.. description::

   Write Kuiper images to SD cards and boot your hardware with
   step-by-step instructions for multiple platforms and tools

After obtaining your Kuiper image (built or downloaded), you'll need to
write it to an SD card or storage device and boot your target hardware.
This section guides you through that process.

----

Extracting the Image
--------------------

The build process produces a zip file in the ``kuiper-volume/`` directory.
Extract it using:

.. shell::
   :caption: Extract the image

   ~/kuiper-volume
   $unzip image_YYYY-MM-DD-ADI-Kuiper-Linux-[arch].zip

----

Writing the Image to an SD Card
-------------------------------

Using Balena Etcher
~~~~~~~~~~~~~~~~~~~

`Balena Etcher <https://www.balena.io/etcher/>`__ provides a simple,
graphical interface for writing images to SD cards and is the
recommended method:

#. **Download and install** `Balena Etcher
   <https://www.balena.io/etcher/>`__.
#. **Launch Etcher** and click "Flash from file".
#. **Select the image file** you extracted from the zip.
#. **Select your SD card** as the target.
#. **Click "Flash"** and wait for the process to complete.

Using Command Line on Linux
~~~~~~~~~~~~~~~~~~~~~~~~~~~

For users who prefer command line tools:

#. **Insert your SD card** into your computer.

#. **Identify the device name** of your SD card:

   .. shell::

      $lsblk
       NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
       sda      8:0    0 465.8G  0 disk
       ├─sda1   8:1    0   512M  0 part /boot/efi
       └─sda2   8:2    0 465.3G  0 part /
       sdb           8:16   1  29.7G  0 disk 
       ├─sdb1        8:17   1     2G  0 part /media/user/BOOT
       ├─sdb2        8:18   1  27.7G  0 part /media/user/rootfs
       └─sdb3        8:19   1     8M  0 part

   Look for a device like ``/dev/sdX`` or ``/dev/mmcblkX`` (where X is a
   letter or number) that matches your SD card's size. In this example,
   ``/dev/sdb`` is a 32GB SD card.

#. **Unmount any auto-mounted partitions**:

   .. shell::

      $sudo umount /dev/sdX*

   Replace ``/dev/sdX`` with your actual device path.

   .. warning::

      Double-check the device name. Writing to the wrong device will
      destroy data on that device.

#. **Write the image to the SD card**:

   .. shell::

      $sudo dd if=image_YYYY-MM-DD-ADI-Kuiper-Linux-[arch].img of=/dev/sdX bs=4M status=progress conv=fsync

   Replace ``/dev/sdX`` with your actual device path, and update the
   image filename accordingly.

   This process may take several minutes depending on image size and SD
   card speed.

#. **Eject the SD card**:

   .. shell::

      $sudo eject /dev/sdX

Alternative Image Writing Tools
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

While Balena Etcher is recommended for its simplicity and cross-platform
support, you can also use these alternatives:

**Linux alternatives**

* GNOME Disks (pre-installed on most GNOME-based distributions)
* Ubuntu Disk Image Writer
* Popsicle

**Windows alternatives**

* Win32 Disk Imager
* Rufus

**All platforms**

* Raspberry Pi Imager (works with any .img file, not just Pi images)

----

.. _use-kuiper-image-before-boot:

Before You Boot: Platform-Specific Requirements
-----------------------------------------------

.. important::

   The next steps depend on your hardware platform. Read this section
   carefully to avoid boot failures.

.. _use-kuiper-image-before-boot-adi:

ADI Evaluation Boards
~~~~~~~~~~~~~~~~~~~~~

ADI evaluation boards (ZedBoard, ZC706, ADRV9009-ZU11EG, etc.) **require
configuration** before your system will boot successfully.

Configuration specifies which evaluation board and carrier combination
you're using, allowing the system to load the correct boot files.

**If you configured during the build process:**

You set ``ADI_EVAL_BOARD`` and ``CARRIER`` parameters in your
configuration file before building.

* Your image is ready to boot
* Continue to :ref:`use-kuiper-image-booting` below

**If you did NOT configure during the build process:**

Your image is not yet configured for any specific hardware.

* **STOP HERE** - Do not boot yet
* See :ref:`ADI Evaluation Boards Configuration
  <hardware-configuration-adi-eval-boards>` to configure your image for your
  specific evaluation board and carrier
* Return here after configuration is complete

Raspberry Pi
~~~~~~~~~~~~

Raspberry Pi images work out-of-box with no configuration required.

* Continue directly to :ref:`use-kuiper-image-booting` below
* For optional customizations like device tree overlays, see
  :ref:`Raspberry Pi Configuration <hardware-configuration-raspberry-pi>` after
  your system is running

----

.. _use-kuiper-image-booting:

Booting Your Device
-------------------

After writing the image to your SD card and completing any required
configuration:

#. **Insert the SD card** into your target device.

#. **Connect required peripherals**:

   * Power supply
   * Display (HDMI or other video output) if using console access
   * Keyboard and mouse if using console access
   * Ethernet cable if using wired network access

#. **Power on the device**.

#. **Wait for first boot to complete**:

   The first boot takes longer than subsequent boots (typically 1-3
   minutes) as the system automatically resizes the root partition to
   use the full SD card capacity.

   **Successful boot indicators:**

   * Console displays login prompt
   * SSH becomes accessible (if network connected)
   * System responds to keyboard input

   **If the system doesn't boot:**

   * For ADI evaluation boards: Verify you completed configuration (see
     :ref:`use-kuiper-image-before-boot-adi`)
   * Check SD card is properly inserted
   * Verify power supply provides adequate current
   * Check display connection if using console access

----

Login Information
-----------------

**Username:** analog

**Password:** analog

Root access is available using the same password with ``sudo`` or by
logging in directly as root.

----

Accessing Your Kuiper System
----------------------------

Console Access
~~~~~~~~~~~~~~

Connect directly with a keyboard and display if your hardware supports
it. This is the most reliable access method for initial setup.

SSH Access
~~~~~~~~~~

If your device is connected to a network, you can access it via SSH.

First, find your device's IP address. If you have console access:

.. shell::

   $ip addr show
    1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
        inet 127.0.0.1/8 scope host lo
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP
        inet 192.168.1.100/24 brd 192.168.1.255 scope global eth0

If you do not, you can try the default hostname:

.. shell::

   $ssh analog@analog.local

Or just look-up the IP address:

.. shell::

   $avahi-resolve-host-name -4 analog.local
    analog.local      192.168.1.100

Or scan the network looking for the device:

.. shell::

   $sudo nmap -sn 192.168.1.0/24
    Nmap scan report for 192.168.1.100
    Host is up (0.00097s latency).
    MAC Address: A6:7C:7E:F2:C5:0D (Xilinx)

In this example, the device IP address is ``192.168.1.100``.

Then connect from another computer:

.. shell::

   $ssh analog@192.168.1.100
    The authenticity of host '192.168.1.100 (192.168.1.100)' can't be established.
    ECDSA key fingerprint is SHA256:...
    Are you sure you want to continue connecting (yes/no)? yes
    analog@192.168.1.100's password:

Enter the password ``analog`` when prompted.

VNC Access
~~~~~~~~~~

If you built your image with ``CONFIG_DESKTOP=y``, you can access the
graphical environment via VNC:

#. Connect to your device using a VNC client (like RealVNC, TigerVNC,
   or Remmina).

#. Use the device's IP address and port 5900, for example:

   .. code-block:: text

      192.168.1.100:5900

#. Enter the password ``analog`` when prompted.

----

Verifying Your Installation
---------------------------

To verify that your Kuiper image is working correctly:

**Check system information:**

.. shell::

   $uname -a
    Linux analog 6.6.63-v8-16k+ #1 SMP PREEMPT Wed Aug 13 10:31:20 UTC 2025 aarch64 GNU/Linux

**Verify ADI tools** (if you included them in your build):

.. shell::

   $iio_info --version
    iio_info version: 0.26 (git tag:ba74e6c5)
    Libiio version: 0.26 (git tag: ba74e6c) backends: local xml ip usb serial

.. shell::

   $iio_info -n 192.168.1.100 | head
    iio_info version: 0.26 (git tag:ba74e6c5)
    Libiio version: 0.26 (git tag: ba74e6c) backends: local xml ip usb serial
    IIO context created with network backend.
    Backend version: 0.26 (git tag: ba74e6c)
    Backend description string: 192.168.1.100 Linux analog 6.6.63-v8-16k+ #1 SMP PREEMPT Wed Aug 13 10:31:20 UTC 2025 aarch64
    IIO context has 5 attributes:
      hw_carrier: Raspberry Pi 5 Model B Rev 1.0
      dtoverlay: vc4-fkms-v3d,dwc2
      local,kernel: 6.6.63-v8-16k+
      uri: ip:192.168.1.100

This command lists IIO devices accessible on the network. If you have
ADI evaluation hardware properly configured and connected, you should
see device information.

.. note::

   The exact output will vary depending on your build configuration,
   hardware platform, and installed packages. The examples above show
   typical successful outputs.

----

Change the hostname and MAC address
-----------------------------------

By default, the hostname is ``analog`` for every Kuiper install. If you have
multiple devices in the same network with the same hostname, mDNS/Avahi won't
work properly. Set-up a new, unique hostname, with:

.. shell::

   $hostnamectl set-hostname analog-my-device
   $systemctl restart avahi-daemon

To persistently change the MAC address will depend on your carrier, you may be
able through ``/boot/uEnv.txt`` by adding ``ethaddr=<new-mac-address>``, or
through Linux through manipulating ``/etc/network/interfaces``. Check the
carrier vendor documentation for full instructions.
