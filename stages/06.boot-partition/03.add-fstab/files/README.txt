INFO: If you are already booting the image on a hardware platfom, run 'sudo configure-setup.sh --help' and follow the steps for automatic preparation of the boot partition.
Check this link for more informations: https://analogdevicesinc.github.io/kuiper/hardware-configuration.html
If not, check the manual steps below:

Platform-Specific Manual Steps

AMD/Xilinx Platforms

For Zynq projects, copy these files to the root of the BOOT FAT32 partition:
    <target>/BOOT.BIN - First stage bootloader with FPGA bitstream
    <target>/<specific_folder>/devicetree.dtb - Device tree for your specific project
    zynq-common/uImage - Kernel image for Zynq platforms
    zynq-common/uEnv.txt - U-Boot environment configuration

For ZynqMP projects, copy these files to the root of the BOOT FAT32 partition:
    <target>/BOOT.BIN - First stage bootloader with FPGA bitstream
    <target>/<specific_folder>/system.dtb - Device tree for your specific project
    zynqmp-common/Image - Kernel image for ZynqMP platforms
    zynqmp-common/uEnv.txt - U-Boot environment configuration

For Versal projects, copy these files to the root of the BOOT FAT32 partition:
    <target>/BOOT.BIN - Platform Loader and Manager (PLM) and boot components
    <target>/<specific_folder>/system.dtb - Device tree for your specific project
    <target>/boot.scr - U-Boot script for Versal boot sequence
    versal-common/Image - Kernel image for Versal platforms


Intel/Altera Platforms

For Arria10 SoC projects, copy these files to the root of the BOOT FAT32 partition:
    <target>/fit_spl_fpga.itb - FPGA configuration and SPL image
    <target>/socfpga_arria10_socdk_sdmmc.dtb - Device tree
    <target>/u-boot.img - U-Boot proper
    socfpga_arria10_common/zImage - Kernel image
Create an extlinux folder in the boot partition and copy socfpga_arria10_common/extlinux.conf into it
Write the preloader (replace mmcblkXp3 with your actual device):
    'sudo dd if=<target>/u-boot-splx4.sfp of=/dev/mmcblk0p3 status=progress'

For Cyclone5 projects, copy these files to the root of the BOOT FAT32 partition:
    <target>/soc_system.rbf - FPGA bitstream
    <target>/socfpga.dtb - Device tree
    <target>/u-boot.scr - U-Boot script
    socfpga_cyclone5_common/zImage - Kernel image
Create an extlinux folder in the boot partition and copy socfpga_cyclone5_common/extlinux.conf into it
Write the preloader (replace mmcblkXp3 with your actual device):
    'sudo dd if=<target>/u-boot-with-spl.sfp of=/dev/mmcblk0p3 status=progress'
    

RaspberryPi

For loading RPI overlays the are 2 methods:
  - you can manually edit /boot/config.txt by adding a new line with
    "dtoverlay=<overlay_name>[,<overlay_arguments>]"
  - or you can load an overlay dinamically, after RPI booted, by opening a
    terminal and typing "sudo dtoverlay <overlay_name>[,<overlay_arguments>]"
In both cases, there needs to be specified only the overlay name, without extension and path.
Overlays binaries (*.dtbo) can be found in /boot/overlays.

INFO: After editing the config.txt file you need to reboot you device so that the changes are loaded.

Documentation:
    https://analogdevicesinc.github.io/kuiper/
    https://analog.com/en/design-center/evaluation-hardware-and-software/software/kuiper-linux.html
