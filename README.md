# ADI Kuiper Linux

Kuiper is a specialized Debian-based Linux distribution designed specifically for Analog Devices hardware and evaluation boards. It provides a complete, ready-to-use environment with ADI libraries, tools, and applications pre-configured for seamless hardware integration.

Whether you're prototyping with an ADI evaluation board, developing embedded applications, or building software-defined radio solutions, Kuiper gives you a solid foundation to start immediately without the complexity of manual system configuration.

📖 **[Complete Documentation](https://analogdevicesinc.github.io/kuiper/)** | 📥 **[Pre-built Images](https://github.com/analogdevicesinc/kuiper/actions/workflows/kuiper2_0-build.yml)** | 🐛 **[Issues](https://github.com/analogdevicesinc/kuiper/issues)** | 💬 **[Community](https://ez.analog.com/linux-software-drivers)**

## Quick Start

1. **Check prerequisites** ([see details](https://analogdevicesinc.github.io/kuiper/prerequisites.html)): Ubuntu 22.04 + Docker
2. **Get Kuiper image**:
   - **Quick option**: Download pre-built from [GitHub Actions](https://github.com/analogdevicesinc/kuiper/actions/workflows/kuiper2_0-build.yml?query=branch:main)
   - **Custom option**: Clone and build your own

   ```bash
   git clone --depth 1 https://github.com/analogdevicesinc/kuiper
   cd kuiper
   sudo ./build-docker.sh
   ```

   For more details, see the [quick start guide](https://analogdevicesinc.github.io/kuiper/quick-start.html).

3. **Write the image** to an SD card and boot your device ([see Using Kuiper Images](https://analogdevicesinc.github.io/kuiper/use-kuiper-image.html))

## Build Configurations

### 🔧 Basic Image (Default)

- Debian Trixie base with boot files for Pi/Xilinx/Intel
- Perfect for headless applications and custom development

### 🖥️ Full Image

- Everything from Basic + XFCE desktop + complete ADI library suite
- Perfect for development workstations and evaluation

### ⚙️ Custom Image

- Configurable combination of any available components  
- Perfect for production deployments and specialized applications

## What's Included

- **Core System**: Debian Trixie optimized for ARM devices
- **ADI Libraries**: libiio, pyadi-iio, libm2k, libad9361, libad9166 (optional)
- **Development Tools**: IIO Oscilloscope, Scopy, GNU Radio (optional)
- **Hardware Support**: Boot files for Raspberry Pi, Xilinx, and Intel platforms
- **Desktop Environment**: XFCE with VNC access (optional)

All optional components are configurable - build exactly what you need for your project.
