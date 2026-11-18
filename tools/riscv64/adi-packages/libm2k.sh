# SPDX-License-Identifier: BSD-3-Clause
#
# kuiper2.0 - Embedded Linux for Analog Devices Products
#
# Copyright (c) 2026 Analog Devices, Inc.
# Author: Vilmos Csaba Jozsa <Vilmoscsaba.jozsa@analog.com>

# libm2k: without the C# bindings (libm2k-csharp). They need Mono, which
# Debian has no riscv64 runtime for (mono-runtime), so neither the build nor
# the board could use them. Sourced by build-pkgs.sh in the build tree.

sed -i -e '/^ *mono-mcs,$/d' -e '/^ *cli-common-dev$/d' -e 's/^\( *dh-python\),$/\1/' debian/control
awk '/^Package: libm2k-csharp$/ { skip = 1 } /^$/ { skip = 0 } !skip' debian/control > debian/control.new
mv debian/control.new debian/control
rm -f debian/libm2k-csharp.install
sed -i 's/-DENABLE_CSHARP=ON/-DENABLE_CSHARP=OFF/' debian/rules
grep -q 'ENABLE_CSHARP=OFF' debian/rules && ! grep -qE 'mono|cli-common|libm2k-csharp' debian/control
