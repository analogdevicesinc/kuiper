.. _networking:

Networking
==========

.. description::

   Configure Ethernet, static IP addresses and Wi-Fi on Kuiper, and reach
   your board over the network

Kuiper is configured to get your board on the network without any setup: plug
in an Ethernet cable and the board acquires an address, either from your
network or by negotiating one directly with the computer at the other end of
the cable.

This page explains what that default configuration does, and how to change it
when you need a fixed address, a Wi-Fi connection, or access to IIO devices
from another machine.

.. note::

   For the first-boot walkthrough of logging in over serial, SSH or VNC, see
   :ref:`Accessing Your Kuiper System <use-kuiper-image>`. This page covers
   configuring the network itself.

----

.. _networking-defaults:

How Kuiper Configures the Network
---------------------------------

Kuiper manages network interfaces with `NetworkManager
<https://networkmanager.dev/>`__. The image ships two connection profiles for
the Ethernet port, and NetworkManager picks between them automatically:

.. list-table::
   :header-rows: 1
   :class: bold-header

   * - Profile
     - Priority
     - What it does
   * - ``Wired connection 1``
     - 10
     - Requests an address over DHCP, waiting up to 5 seconds for a reply
   * - ``eth0-linklocal``
     - 5
     - Assigns a link-local address in the ``169.254.x.x`` range

The higher-priority DHCP profile is tried first. If no DHCP server answers
within 5 seconds — which is what happens when the board is cabled straight to
a PC — NetworkManager falls back to the link-local profile. **You do not need
to configure anything for a direct board-to-PC connection.**

Both profiles live in ``/etc/NetworkManager/system-connections/`` on the
running system.

A few other defaults are worth knowing:

**Interface names are predictable-name-free**
   Kuiper disables systemd's predictable interface naming, so the ports use
   the classic kernel names ``eth0``, ``wlan0`` and ``usb0`` rather than names
   like ``enx00044b`` or ``end0``. Both shipped profiles are bound to ``eth0``
   by name.

**IPv6 is disabled**
   Both Ethernet profiles set ``method=disabled`` for IPv6. Kuiper is reachable
   over IPv4 only unless you enable IPv6 yourself.

**The board is discoverable as** ``analog.local``
   ``avahi-daemon`` and ``libnss-mdns`` are installed, so the board advertises
   itself over mDNS using its hostname. See :ref:`networking-hostname`.

**SSH is enabled and starts at boot**
   ``openssh-server`` is part of every image, including Basic builds. Review
   :ref:`networking-security` before putting a board on an untrusted network.

.. note::

   Wi-Fi is not part of this default configuration. Only the Ethernet port is
   preconfigured — see :ref:`networking-wifi` to connect wirelessly.

----

.. _networking-dhcp:

Connecting to a Network with DHCP
---------------------------------

This is the default. Connect the board's Ethernet port to a router or switch
and power it on; it will request an address automatically.

To check the address the board received:

.. shell::

   $ip addr show eth0
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP
        inet 192.168.1.100/24 brd 192.168.1.255 scope global eth0

An address in the ``169.254.x.x`` range means DHCP did not answer and the
link-local fallback took over — see :ref:`networking-direct`.

You can also inspect the connection through NetworkManager:

.. shell::

   $nmcli device status
    DEVICE  TYPE      STATE                   CONNECTION
    eth0    ethernet  connected               Wired connection 1
    lo      loopback  connected (externally)  lo

The ``CONNECTION`` column tells you which profile is active.

Requesting a New Address
~~~~~~~~~~~~~~~~~~~~~~~~

If you need the board to request a fresh lease — after moving it to a
different network, for example — bring the connection down and back up:

.. shell::

   $sudo nmcli connection down "Wired connection 1"
   $sudo nmcli connection up "Wired connection 1"

.. note::

   Older ADI documentation suggests ``sudo dhclient -r eth0`` for this.
   Kuiper does not use ``dhclient``; use the ``nmcli`` commands above.

----

.. _networking-direct:

Connecting Directly to a PC
---------------------------

To connect the board straight to a computer with a single Ethernet cable, with
no router or switch in between, just plug the cable in. Kuiper handles the rest.

Because no DHCP server responds, the DHCP profile times out after 5 seconds
and NetworkManager activates the ``eth0-linklocal`` profile, giving the board
an address in the ``169.254.x.x`` range. Every modern operating system does the
same on an unconfigured wired interface, so the two ends land on the same
link-local network and can reach each other.

Allow roughly 10 seconds after connecting the cable for the fallback to
happen, then confirm the address on the board:

.. shell::

   $ip addr show eth0
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP
        inet 169.254.8.21/16 brd 169.254.255.255 scope link eth0

From the PC, reach the board by hostname rather than by address — the
link-local address is negotiated at random and changes:

.. shell::

   $ssh analog@analog.local

.. tip::

   On the PC side, make sure the wired interface is set to obtain an address
   automatically (its normal default). If you previously gave it a static
   address for an older Kuiper release, set it back to automatic — otherwise
   it will not join the link-local network.

Setting a static IP address on both ends, as required by earlier Kuiper
versions, is no longer necessary for a direct connection.

----

.. _networking-static-ip:

Setting a Static IP Address
---------------------------

A fixed address is useful when a board must stay reachable at a known location
— in an automated test rack, or when a client application has an address
compiled into it.

There are two ways to do this. ``nmcli`` is the general method and is shown
first; if you have used Kuiper before, the ADI helper scripts described in
:ref:`networking-static-ip-scripts` do the same job in a single command.

Set a static address on the default wired profile:

.. shell::

   $sudo nmcli connection modify "Wired connection 1" \
       ipv4.method manual \
       ipv4.addresses 192.168.1.50/24 \
       ipv4.gateway 192.168.1.1 \
       ipv4.dns "8.8.8.8 8.8.4.4"
   $sudo nmcli connection up "Wired connection 1"

Adjust the address, gateway and DNS servers to match your network. The ``/24``
suffix is the subnet prefix length, equivalent to a ``255.255.255.0`` netmask.

.. note::

   Omit ``ipv4.gateway`` and ``ipv4.dns`` for an isolated point-to-point link
   with no route to the wider network. Setting a gateway that does not exist
   will make the board slow to resolve names.

Verify the result:

.. shell::

   $ip addr show eth0
    2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP
        inet 192.168.1.50/24 brd 192.168.1.255 scope global eth0

The setting is written to the profile and survives reboots.

Reverting to DHCP
~~~~~~~~~~~~~~~~~

To hand addressing back to the network:

.. shell::

   $sudo nmcli connection modify "Wired connection 1" \
       ipv4.method auto \
       ipv4.gateway "" \
       ipv4.addresses ""
   $sudo nmcli connection up "Wired connection 1"

Clearing ``ipv4.addresses`` and ``ipv4.gateway`` matters — a leftover static
address stays configured alongside the DHCP lease.

.. _networking-static-ip-scripts:

Using the ADI Helper Scripts
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Kuiper images include two scripts that wrap the same configuration in a single
command. They come from the ``adi-scripts`` package and have been part of
Kuiper for a long time, so you may already be using them.

To set a static address:

.. shell::

   $sudo enable_static_ip.sh 192.168.0.101 eth0

Both arguments are optional: the address defaults to ``192.168.0.101`` and the
interface to ``eth0``. The netmask is always ``255.255.255.0``, and no gateway
or DNS server is configured — the scripts are aimed at point-to-point links
rather than at joining a routed network.

To hand addressing back to DHCP:

.. shell::

   $sudo enable_dhcp.sh

.. note::

   These scripts write ``/etc/network/interfaces`` and set ``managed=true``
   for NetworkManager's ifupdown plugin, which takes ``eth0`` over from the
   shipped profiles — the DHCP and link-local fallback described in
   :ref:`networking-defaults` no longer apply until you run
   ``enable_dhcp.sh``.

Use ``nmcli`` instead when you need a gateway, DNS servers, a netmask other
than ``/24``, or want to keep the shipped profiles in charge of the interface.

----

.. _networking-wifi:

Connecting to Wi-Fi
-------------------

Wi-Fi is not configured by default and support depends on your build:

- **Raspberry Pi images** (``CONFIG_RPI_BOOT_FILES=y``, the default) include
  the Broadcom Wi-Fi firmware and ``wpasupplicant``, so the onboard adapter
  works.
- **Desktop images** (``CONFIG_DESKTOP=y``) additionally include the
  NetworkManager applet, letting you connect from the XFCE panel.
- **Other platforms** need a supported USB Wi-Fi adapter and its firmware.

Confirm the adapter was detected:

.. shell::

   $nmcli device status
    DEVICE  TYPE      STATE         CONNECTION
    eth0    ethernet  connected     Wired connection 1
    wlan0   wifi      disconnected  --

If no ``wifi`` device is listed, the adapter or its firmware is missing rather
than misconfigured.

Scan for networks and connect:

.. shell::

   $sudo nmcli device wifi list
   $sudo nmcli device wifi connect "MyNetwork" password "MyPassword"

The connection is saved as a new profile and reconnects automatically at boot.

.. note::

   Some regions require a regulatory domain before the adapter will use all
   available channels. Kuiper does not set one. If networks are missing from
   the scan, set your country code with ``sudo iw reg set <code>`` (for
   example ``sudo iw reg set US``).

----

.. _networking-hostname:

Hostname and Network Discovery
------------------------------

Every Kuiper image uses the hostname ``analog`` unless you change it, and
advertises itself over mDNS at ``<hostname>.local``. That is what makes
``ssh analog@analog.local`` work without knowing the IP address.

To look up the address behind the name from another machine:

.. shell::

   $avahi-resolve-host-name -4 analog.local
    analog.local      192.168.1.100

.. important::

   Two boards with the same hostname on one network will collide, and mDNS
   resolution becomes unreliable — you cannot predict which board answers.
   Give each board a unique hostname when running more than one.

Changing the Hostname
~~~~~~~~~~~~~~~~~~~~~

On a running system:

.. shell::

   $sudo hostnamectl set-hostname analog-my-device
   $sudo systemctl restart avahi-daemon

The board is then reachable at ``analog-my-device.local``.

To bake the hostname into the image instead, set ``HOSTNAME`` in the
:doc:`config file <configuration>` before building. This is the better option
when provisioning several boards at once.

Changing the MAC Address
~~~~~~~~~~~~~~~~~~~~~~~~

How to persistently change the MAC address depends on your carrier. You may be
able to set it through ``/boot/uEnv.txt`` by adding
``ethaddr=<new-mac-address>``. Check the carrier vendor documentation for full
instructions.

----

.. _networking-iio:

Accessing IIO Devices over the Network
--------------------------------------

Images built with ``CONFIG_LIBIIO=y`` include ``iiod``, the IIO daemon. It
serves the board's IIO devices over TCP port **30431**, so tools running on
another machine can reach hardware attached to the board.

From a remote machine with libiio installed, pass the board's address with
``-n``:

.. shell::

   $iio_info -n 192.168.1.100 | head
    Library version: 0.26 (git tag: ba74e6c)
    IIO context created with network backend.
    Backend description string: 192.168.1.100 Linux analog 6.6.63-v8-16k+
    IIO context has 5 attributes:
      hw_carrier: Raspberry Pi 5 Model B Rev 1.0
      uri: ip:192.168.1.100

The hostname works here too, which is more convenient on a link-local direct
connection where the address is unpredictable:

.. shell::

   $iio_info -u ip:analog.local

Applications that accept a libiio URI — IIO Oscilloscope, Scopy, pyadi-iio —
take the same ``ip:`` form:

.. code-block:: text

   ip:192.168.1.100
   ip:analog.local

If the connection is refused, check that the daemon is running on the board:

.. shell::

   $systemctl status iiod

.. note::

   ``iiod`` accepts connections from anywhere on the network without
   authentication. Keep boards serving IIO devices on trusted networks.

----

.. _networking-security:

Securing Network Access
-----------------------

Kuiper's defaults favor getting a board reachable quickly, which is the right
trade-off on a lab bench and the wrong one on an untrusted network. Before
connecting a board to the internet or a shared network, be aware that:

- **The default credentials are published.** Both ``analog`` and ``root`` use
  the password ``analog``, and SSH accepts password authentication.
- **Root can log in directly over SSH.** Kuiper sets ``PermitRootLogin yes``.
- **SSH host keys are built into the image.** Every board flashed from the same
  image shares them, so host-key verification cannot distinguish one board from
  another.
- **VNC is exposed on all interfaces.** Desktop images run x11vnc on port 5900
  with the password ``analog``.

At minimum, change the password on first boot:

.. shell::

   $passwd

To change it before the board ever boots, see
:ref:`Change the password on disk <login-change-on-disk>`.

Regenerate the SSH host keys so the board has its own identity:

.. shell::

   $sudo rm /etc/ssh/ssh_host_*
   $sudo dpkg-reconfigure openssh-server

For a board that must be exposed more widely, also consider disabling password
authentication in favor of SSH keys, and setting ``PermitRootLogin no`` in
``/etc/ssh/sshd_config``.
