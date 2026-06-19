#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2024 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

# Check if the system has a display output
if grep -q "^connected$" /sys/class/drm/*/status; then
	# Remove dummy display
	rm -f /usr/share/X11/xorg.conf.d/xorg.conf
else
	# Enable dummy display
	enable_dummy_display.sh
	
	# Wait for lightdm to start
	sleep 5
	
	# Start Xorg if no display server is running yet
	if ! pgrep -f "Xorg" >/dev/null; then
		# Start an X server as user 'analog'
		su - analog -c "startx -- :0 &"
		
		# Export the display port
		export DISPLAY=:0
	fi
fi
