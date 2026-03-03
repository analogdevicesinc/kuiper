#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2025 Analog Devices, Inc.
# Author: Larisa Radu <larisa.radu@analog.com>

PACKAGE=1
VERSION=2

FILE=LICENSE.html

html_header () {
	echo "<!DOCTYPE html>" > ${FILE}
	echo "<html class=\"no-js\" lang=\"en\">" >> ${FILE}
	echo "<head>" >> ${FILE}
	echo "<meta charset=\"utf-8\">" >> ${FILE}
	echo "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" >> ${FILE}
	echo "<meta http-equiv=\"x-ua-compatible\" content=\"ie=edge\">" >> ${FILE}
	echo "<title>$1</title>" >> ${FILE}
	echo "<link type=\"text/css\" href=\"./img/style.css\" rel=\"stylesheet\">" >> ${FILE}
	echo "<link rel=\"apple-touch-icon\" href=\"apple-touch-icon.png\">" >> ${FILE}
	echo "<link rel=\"shortcut icon\" href=\"img/favicon.ico\" type=\"image/x-icon\">" >> ${FILE}
	echo "<link type=\"text/css\" href=\"./img/style.css\" rel=\"stylesheet\">" >> ${FILE}
	echo "</head>" >> ${FILE}
	echo "<body>" >> ${FILE}
	echo "<!--[if lte IE 11]>" >> ${FILE}
	echo "<p class=\"browserupgrade\">You are using an <strong>outdated</strong> browser. Please <a href=\"http://browsehappy.com/\">upgrade your browser</a> to improve your experience and security.</p>" >> ${FILE}
	echo "<![endif]-->" >> ${FILE}

	echo "<header id=\"top\">" >> ${FILE}
	echo "<a href=\"http://www.analog.com\">" >> ${FILE}
	echo "<img src=\"img/ADI_Logo_AWP.png\" alt=\"Analog Devices logo\" />" >> ${FILE}
	echo "</a>" >> ${FILE}
	echo "<div class=\"anchor\">" >> ${FILE}
	echo "</div>" >> ${FILE}

	echo "</header>" >> ${FILE}
	echo "<hr>" >> ${FILE}
}

html_footer () {
	echo "</body>" >> ${FILE}
	echo "</html>" >> ${FILE}
}

html_h1 () {
	echo "<h1>$1</h1>" >> ${FILE}
}

html_h1_id () {
	echo "<div class=\"anchor\"><a href=\"#version\">Back to list</a> | <a href=\"#top\">Back to top</a></div>" >> ${FILE}
	echo "<h1 id=\"P$2\">$1</h1>" >> ${FILE}
}

html_h2 () {
	echo "<h2>$1</h2>" >> ${FILE}
}

html_p () {
	echo "<p>$1</p>" >> ${FILE}
}

html_pre_file () {
	mkdir -p "copyright/${2}"
	echo "<pre>" >> "copyright/$2/${2}.html"
	# get the file, but html sanitize a few things
	find $1 -type f -exec cat {} + | sed -e "s/\o14//g" -e "s/\o302\o251/\&copy;/g" -e "s/'/\&39;/g" -e "s/</\&lt;/g" -e "s/>/\&gt;/g" >> "copyright/$2/${2}.html"
	echo "</pre>" >> "copyright/$2/${2}.html"
}

html_li () {
	echo "<li>$1</li>" >> ${FILE}
}

html_li_start () {
	echo "<ul>" >> ${FILE}
}

html_li_stop () {
	echo "</ul>" >> ${FILE}
}

html_hr () {
	echo "<hr>" >> ${FILE}
}

get_column () {
	echo ${1} | cut -d " " -f ${2}
}

get_version () {
	dpkg -l | awk '{ print $2 " " $3 }' | grep ${1} | cut -d ' ' -f2
}

package_list_items () {
	html_li_start
	html_li "Version: ${1}"
	html_li "License: ${2}"
	html_li "Source Site: <a href=\"${3}\">${3}</a>"
	html_li_stop
}

strstr () {
	echo $1 | grep --quiet $2
}

# package_table_items $((var++)) Linux $(get_version linux) "GPLv2" "https://github.com/analogdevicesinc/linux"
#                     1          2     3                    4       5
package_table_items () {
	url=$5

	echo "<tr>" >> ${FILE}
	echo "<td><a href=\"copyright/${2}/${2}.html\">${2}</a></td>" >> ${FILE}
	echo "<td><a href=\"copyright/${2}/${2}.html\">${4}</a></td>" >> ${FILE}
	echo "<td>${3}</td>" >> ${FILE}
	if [ ! -z "$url" ]; then
		echo -n "<td><a href=\"${url}\">" >> ${FILE}
		if $(strstr $url github) ; then
			echo -n "Github" >> ${FILE}
		elif $(strstr $url sourceforge) ; then
			echo -n "SourceForge" >> ${FILE}
		elif $(strstr $url freedesktop) ; then
			echo -n "Freedesktop" >> ${FILE}
		elif $(strstr $url debian) ; then
			echo -n "Debian Project" >> ${FILE}
		elif $(strstr $url kernel) ; then
			echo -n "Kernel.org" >> ${FILE}
		else
			echo -n "Project" >> ${FILE}
		fi
		echo "</a></td>" >> ${FILE}
	fi
	echo "</tr>" >> ${FILE}
}

# Borrowed concepts from :
# https://github.com/chadbraunduin/markdown.bash/blob/master/markdown.sh
# MIT License
# Copyright (c) 2016 Chad Braun-Duin
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
convert_md2html () {
temp_file="/tmp/markdown.$$"
cat "$1" > "$temp_file"
# All of this below business is for reference-style links and images
# We need to loop across newlines and not spaces
IFS='
'
refs=$(sed -nr "/\[.+\]/p" "$1")
for ref in $refs
do
	ref=$(echo -n "$ref" | sed "s/^.*\[/\[/")
	ref_id=$(echo -n "$ref" | sed -nr "s/^\[(.+)\].*/\1/p" | tr -d '\n')
	ref_url=$(echo -n "$ref" | sed -nr "s/^\[.+\]\((.+)/\1/p" | cut -d' ' -f1 | tr -d '\n')
	ref_title=$(echo -n "$ref" | sed -nr "s/^\[.+\](.+) \"(.+)\"/\2/p" | sed 's@|@!@g' | tr -d '\n' | sed 's/).*$//')
	# reference-style image using the label
	sed -ri "s|!\[([^]]+)\]\[($ref_id)\]|<img src=\"$ref_url\" title=\"$ref_title\" alt=\"\1\" />|gI" "$temp_file"
	# reference-style link using the label
	sed -ri "s|\[($ref_id)\].*\($ref_url \"$ref_title\"\)|<a href=\"$ref_url\" title=\"$ref_title\">\1</a>|gI" "$temp_file"
	# implicit reference-style
	sed -ri "s|!\[($ref_id)\]\[\]|<img src=\"$ref_url\" title=\"$ref_title\" alt=\"\1\" />|gI" "$temp_file"
	# implicit reference-style
	sed -ri "s|\[($ref_id)\]\[\]|<a href=\"$ref_url\" title=\"$ref_title\">\1</a>|gI" "$temp_file"
done

# delete the reference lines
sed -ri "/^\[.+\]: +/d" "$temp_file"
sed -nri "/^# /,/^# /  { /^# /d ; p } " "$temp_file"
sed -ri -e 's/^$/<p>/' "$temp_file"
cat ${temp_file}
rm ${temp_file}
}

### main
mkdir -p copyright

html_header "${TARGET} Legal Information"

html_h1 "Legal Information"

convert_md2html stages/08.export-stage/03.generate-license/LICENSE.md >> ${FILE}

echo "<div class=\"boxed\">" >> ${FILE}
html_h2 "Written Offer"

echo "<p>As described above, the Image included in the ${TARGET} contains copyrighted software that is released and distributed under many licenses, including the GPL.
A copy of the licenses are included in this file (below)." >> ${FILE}

echo "You may obtain the complete Corresponding Source code from us for a period of three years after our last shipment of this product, which will be no earlier than " >> ${FILE}
date --date="3 years 6 months" +"%d%b%Y" >> ${FILE}
echo ", by sending a money order or check for \$15 (USD) to:</p>
<pre>
Director, Open Source Program Office
Analog Devices
Floors 1 - 3
2 Freer Street
Edinburgh
EH3 9FQ
United Kingdom
</pre>
<p>Please write “<i>source for the ${TARGET}</i>” in the memo line of your payment.
Since the source does not fit on a DVD-RW, it will be delivered on a USB Thumb drive (hence the higher cost than just DVD or CD).</p>
<p><b>You will also find the source on-line, and are encouraged to obtain it for zero cost, at the project web sites.</b></p>
</div>" >> ${FILE}

html_h2 "NO WARRANTY"

echo "<pre>" >> ${FILE}
cat stages/08.export-stage/03.generate-license/LICENSE.md | sed  -n '1,/# NO WARRANTY/!p' | sed "1d" >> ${FILE}
echo "</pre>" >> ${FILE}

### Table of packages
html_h1 "Open source components/packages:"

var=0
echo "<p id=\"version\"><strong>Version Information:</strong></p>" >> ${FILE}
echo "<table>" >> ${FILE}
echo "<thead>" >> ${FILE}
echo "<tr>" >> ${FILE}
echo "<th>Package</th>" >> ${FILE}
echo "<th>License</th>" >> ${FILE}
echo "<th>Version</th>" >> ${FILE}
echo "<th>Location</th>" >> ${FILE}
echo "</tr>" >> ${FILE}
echo "</thead>" >> ${FILE}
echo "<tbody>" >> ${FILE}

if [[ "${CONFIG_RPI_BOOT_FILES}" = y || "${CONFIG_XILINX_INTEL_BOOT_FILES}" = y ]]; then
	package_table_items $((var++)) "linux" $BRANCH_RPI_BOOT_FILES "GPLv2" "https://github.com/analogdevicesinc/linux"
	wget https://raw.githubusercontent.com/analogdevicesinc/linux/main/COPYING
	html_pre_file COPYING linux
	rm COPYING
fi

if [ "${CONFIG_XILINX_INTEL_BOOT_FILES}" = y ]; then
	package_table_items $((var++)) "hdl" $RELEASE_XILINX_INTEL_BOOT_FILES "GPL/LGPL/BSD" "https://github.com/analogdevicesinc/hdl"
	wget https://raw.githubusercontent.com/analogdevicesinc/hdl/main/LICENSE
	html_pre_file LICENSE hdl
	rm LICENSE
fi

if [ "${CONFIG_LIBIIO}" = y ]; then
	package_table_items $((var++)) "libiio" ${BRANCH_LIBIIO} "LGPL-2.1/GPL-2.0" "https://github.com/analogdevicesinc/libiio"
	html_pre_file /usr/local/src/libiio/COPYING.txt libiio
fi

if [ "${CONFIG_PYADI}" = y ]; then
	package_table_items $((var++)) "pyadi-iio" ${BRANCH_PYADI} "ADI BSD" "https://github.com/analogdevicesinc/pyadi-iio"
	html_pre_file /usr/local/src/pyadi-iio/LICENSE pyadi-iio
fi

if [ "${CONFIG_LIBM2K}" = y ]; then
	package_table_items $((var++)) "libm2k" ${BRANCH_LIBM2K} "LGPL-2.1" "https://github.com/analogdevicesinc/libm2k"
	html_pre_file /usr/local/src/libm2k/LICENSE libm2k
fi

if [ "${CONFIG_LIBAD9166_IIO}" = y ]; then
	package_table_items $((var++)) "libad9166-iio" ${BRANCH_LIBAD9166_IIO} "GPL-2.1" "https://github.com/analogdevicesinc/libad9166-iio"
	html_pre_file /usr/local/src/libad9166-iio/LICENSE libad9166-iio
fi

if [ "${CONFIG_LIBAD9361_IIO}" = y ]; then
	package_table_items $((var++)) "libad9361-iio" ${BRANCH_LIBAD9361_IIO} "LGPL-2.1" "https://github.com/analogdevicesinc/libad9361-iio"
	html_pre_file /usr/local/src/libad9361-iio/LICENSE libad9361-iio
fi

if [ "${CONFIG_IIO_OSCILLOSCOPE}" = y ]; then
	package_table_items $((var++)) "iio-oscilloscope" ${BRANCH_IIO_OSCILLOSCOPE} "GPL-2.0" "https://github.com/analogdevicesinc/iio-oscilloscope"
	html_pre_file /usr/local/src/iio-oscilloscope/LICENSE iio-oscilloscope
fi

if [ "${CONFIG_IIO_FM_RADIO}" = y ]; then
	package_table_items $((var++)) "iio-fm-radio" ${BRANCH_IIO_FM_RADIO} "GPL-2.0" "https://github.com/analogdevicesinc/iio-fm-radio"
	html_pre_file /usr/local/src/iio-fm-radio/license.txt iio-fm-radio
fi

if [ "${CONFIG_FRU_TOOLS}" = y ]; then
	package_table_items $((var++)) "fru_tools" ${BRANCH_FRU_TOOLS} "GPL-2.0" "https://github.com/analogdevicesinc/fru_tools"
	html_pre_file /usr/local/src/fru_tools/license.txt fru_tools
fi

if [ "${CONFIG_JESD_EYE_SCAN_GTK}" = y ]; then
	package_table_items $((var++)) "jesd-eye-scan-gtk" ${BRANCH_JESD_EYE_SCAN_GTK} "LGPL-2.1/GPL-2.0" "https://github.com/analogdevicesinc/jesd-eye-scan-gtk"
	html_pre_file /usr/local/src/jesd-eye-scan-gtk/LICENSE.txt jesd-eye-scan-gtk
fi

if [ "${CONFIG_COLORIMETER}" = y ]; then
	package_table_items $((var++)) "colorimeter" ${BRANCH_COLORIMETER} "LGPL-2.1/GPL-2.0" "https://github.com/analogdevicesinc/colorimeter"
	html_pre_file /usr/local/src/colorimeter/LICENSE.txt colorimeter
fi

if [ "${CONFIG_SCOPY}" = y ]; then
	package_table_items $((var++)) "scopy" " " "GPL-3.0" "https://github.com/analogdevicesinc/scopy"
	wget https://raw.githubusercontent.com/analogdevicesinc/scopy/main/LICENSE
	html_pre_file LICENSE scopy
	rm LICENSE
fi

if [ "${CONFIG_GRM2K}" = y ]; then
	package_table_items $((var++)) "gr-m2k" ${BRANCH_GRM2K} "GPL-3.0" "https://github.com/analogdevicesinc/gr-m2k"
	html_pre_file /usr/local/src/gr-m2k/COPYING gr-m2k
fi

if [ "${CONFIG_LINUX_SCRIPTS}" = y ]; then
	package_table_items $((var++)) "linux_image_ADI-scripts" " " "GPL-3.0" "https://github.com/analogdevicesinc/linux_image_ADI-scripts"
	html_pre_file /usr/local/src/linux_image_ADI-scripts/LICENSE linux_image_ADI-scripts
fi

dpkg -l | awk '/ii/ { print $2 " " $3 }' | while read -r line
do
        package=$(get_column "${line}" $PACKAGE | cut -f1 -d":")

        version=$(get_column "${line}" $VERSION)
        license_file="/usr/share/doc/$package/copyright"
        license=$(awk '/^License:/ { print $2 }' "$license_file")
        source_site=$(awk '/^Source:/ { print $2 }' "$license_file")

        package_table_items $((var++)) $package $version "$license" $source_site

	html_pre_file $license_file $package
done

if command -v pip3 &> /dev/null; then
	pip3 list --format=freeze | cut -d'=' -f1 | while read -r package; do
		pip_info=$(pip3 show "$package" 2>/dev/null)

		if [ $? -eq 0 ]; then
			version=$(echo "$pip_info" | grep "^Version:" | cut -d' ' -f2)
			license=$(echo "$pip_info" | grep "^License:" | cut -d' ' -f2- | sed 's/^# *//')
			source_site=$(echo "$pip_info" | grep "^Home-page:" | cut -d' ' -f2)

			package_table_items $((var++)) "python-$package" "$version" "$license" "$source_site"

			echo "$pip_info" > "/tmp/pip_${package}_info"
			html_pre_file "/tmp/pip_${package}_info" "python-$package"
			rm "/tmp/pip_${package}_info"
		fi
	done
  fi

echo "</tbody>" >> ${FILE}
echo "</table>" >> ${FILE}

html_footer

cp /LICENSE.html /licensing
cp -r /copyright /licensing

cp -r stages/08.export-stage/03.generate-license/img /

chown analog:analog /LICENSE.html
chown -R analog:analog /copyright
chown -R analog:analog /img
