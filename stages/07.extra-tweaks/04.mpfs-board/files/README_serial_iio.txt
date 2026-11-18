IIO over the USB serial port (PolarFire SoC Video Kit)
=====================================================

By default the USB device port of the Video Kit is a composite USB gadget:
- an ACM serial port (on the board: /dev/ttyGS0, with a login console, see
  below),
- the IIO FunctionFS of iiod (on the host: usb:... in iio_info -s and Scopy),
  with 2 endpoint pairs (-n 2): one buffer at a time.

iiod can also serve IIO on the ACM serial port. Then the host reaches the
board as serial:COMx,115200,8n1 (Windows) or serial:/dev/ttyACM0,115200,8n1
(Linux), with the standard serial driver, no extra driver. The serial port is
then used by iiod, so its login console is turned off; the Linux console stays
on the debug UART (ttyS1, 115200 8N1).

Enable (on the board, as root):

    sed -i 's|^IIOD_EXTRA_FFS_OPTS=.*|IIOD_EXTRA_FFS_OPTS="-n 2 -F /dev/iio_ffs -s /dev/ttyGS0,115200,8n1"|' /etc/default/iiod
    systemctl disable serial-getty@ttyGS0.service
    reboot

Use (on the host, COMx is the new USB serial port in the Device Manager):

    iio_info -u serial:COMx,115200,8n1

    Scopy: add the device with the URI serial:COMx,115200,8n1

    pyadi-iio: adi.ad9361(uri="serial:COMx,115200,8n1")

Serial IIO is slow: fine for the attributes and the control, slow for
buffers. Network (ip:<board address>) and USB (usb:...) keep working.

Disable (back to the default):

    sed -i 's|^IIOD_EXTRA_FFS_OPTS=.*|IIOD_EXTRA_FFS_OPTS="-n 2 -F /dev/iio_ffs"|' /etc/default/iiod
    systemctl enable serial-getty@ttyGS0.service
    reboot

Do not set -n 3: the USB controller of the PolarFire SoC has 4 IN and 4 OUT
endpoints, the ACM takes 2 IN and 1 OUT, and with 3 iiod endpoint pairs the
gadget does not start (gt-start.service fails), so neither the serial port
nor the USB IIO appear.

Login console on the USB serial port
------------------------------------

The login console on the ACM serial port (ttyGS0) runs without the TTY reset
of systemd (/etc/systemd/system/serial-getty@ttyGS0.service.d/no-reset.conf):
at boot, systemd resets each console under one lock, and while no USB host
reads the ACM port, the reset of ttyGS0 would block with the lock held, so the
console of the debug UART (ttyS1) would get no login prompt. Keep the file;
without it, if the ttyS1 login does not come, log in over ssh and run
'systemctl stop serial-getty@ttyGS0.service'.
