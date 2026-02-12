#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

if [ "${CONFIG_DESKTOP}" = y ]; then

mkdir "${BUILD_DIR}/usr/share/adi-wallpaper"
install -m 644 "${BASH_SOURCE%%/run.sh}"/files/wallpaper.png "${BUILD_DIR}/usr/share/adi-wallpaper"
rm "${BUILD_DIR}/usr/share/icons/hicolor/16x16/apps/org.xfce.panel.applicationsmenu.png"
install -m 644 "${BASH_SOURCE%%/run.sh}"/files/org.xfce.panel.applicationsmenu.png "${BUILD_DIR}/usr/share/icons/hicolor/16x16/apps"

chroot "${BUILD_DIR}" << EOF
	# Set theme to dark
	sed -i "s/Xfce/Adwaita-dark/g" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

	# Set adi-wallpaper to all workspaces
	rm /usr/share/backgrounds/xfce/xfce-x.svg
	ln -s /usr/share/adi-wallpaper/wallpaper.png /usr/share/backgrounds/xfce/xfce-x.svg

	# Disable screen saver
	sed -i '/exec \${XFCE4_SESSION_COMPOSITOR:-xfce4-session}/i xset s off\nxset -dpms\nxset s noblank' /etc/xdg/xfce4/xinitrc
	
	# Change menu name
	sed -i "s/Name=Science/Name=Analog Devices Tools/g" /usr/share/desktop-directories/xfce-science.directory
	
	# Exclude 'Development' category from 'Science' menu
	sed -i '/<Category>Science/{n;n;s/^/<Exclude><Category>Development<\/Category><\/Exclude>\n/}' /etc/xdg/menus/xfce-applications.menu
EOF

else
	echo "Desktop cosmetics won't be installed because CONFIG_DESKTOP is set to 'n'."
fi
