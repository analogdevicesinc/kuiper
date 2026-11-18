<!--
SPDX-License-Identifier: BSD-3-Clause
Copyright (c) 2026 Analog Devices, Inc.
-->

# riscv64 tools

The ADI package repository has no riscv64 packages yet, so
`build-adi-packages.sh` builds the ADI packages that the `05.adi-tools` stages
install, into the local package repository `kuiper-build-temp/adi-local-repo`
(`ADI_LOCAL_REPO` of `config`). The full description is in
[docs/polarfire-soc.rst](../../docs/polarfire-soc.rst).

```sh
tools/riscv64/build-adi-packages.sh
```

- It builds each repository of `ADI_PACKAGES` (in the script, at fixed
  commits) with the steps of the ADI CI (the `deb-generator-action` of
  `analogdevicesinc/shared-actions`): the `packaging/debian` of the
  repository, its build dependencies, `debuild`.
- Each build environment is a Debian of the release and the snapshot of
  `config`, made by `mmdebstrap` without root and thrown away after the build:
  cross-compiled in an amd64 one by default, natively in a riscv64 one under
  qemu for the packaging that does not cross-compile.
- A package already in the repository at its version is not built again.
- The logs are in `kuiper-build-temp/adi-local-repo-logs`.
- The sources and the inputs of the build environments are in
  `kuiper-build-temp/riscv64-packages` (`KUIPER_BUILD_TEMP`, default
  `kuiper-build-temp`, in `.gitignore`), the build environments in
  `kuiper-build-env-<uid>-<id>` of `KUIPER_BUILD_ENV_TEMP` (default `TMPDIR`,
  or `/tmp`), during the build only: they are removed at the end, also when
  the build fails or is interrupted, and at the start, if a killed run left
  them.
- `mmdebstrap` builds without root in a user namespace, whose root is the
  first subordinate uid of the user (`/etc/subuid`): it must reach the build
  environments, with the search (`x`) permission on the directories above
  them. A home directory of mode 750 does not let it pass, so
  `KUIPER_BUILD_ENV_TEMP=kuiper-build-temp` needs e.g. `setfacl -m
  u:<subordinate uid>:x <home>` (or `chmod o+x <home>`). The tool checks it
  first and names the directory that it cannot pass; it does not change the
  permissions.
- The build environments trust the certificates of the build host
  (`/etc/ssl/certs/ca-certificates.crt`): behind a TLS-inspecting proxy,
  install the certificate of the proxy on the build host.

`adi-packages/` holds what differs from the ADI packaging:

| File | Why |
|---|---|
| `build-pkgs.sh` | The build of the packages inside a build environment |
| `libm2k.sh` | No `libm2k-csharp`: Debian has no riscv64 Mono runtime |
| `iio-oscilloscope.sh` | Built from source: the ADI package repackages the AppImage, which has no riscv64 build |
| `gt/` | The packaging of the USB Gadget Tool, which `adi-scripts` depends on and whose ADI packaging is not public |

With the riscv64 packages in the ADI package repository, this tool and
`ADI_LOCAL_REPO` are no longer needed.
