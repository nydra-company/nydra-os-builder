# Nydra OS Builder

An automated live-build setup for **Nydra OS 1.0** — a lightweight Debian-based operating system featuring a customized GNOME desktop experience, dark theme integration, and the Calamares graphical installer.

---

## 📌 System Requirements

Before starting the build process, ensure your host environment meets the following minimum specifications:

| Resource | Requirement |
| --- | --- |
| **Host OS** | Debian 12 (Bookworm) or Ubuntu 22.04+ (64-bit) |
| **CPU Architecture** | x86_64 / amd64 |
| **RAM** | 4 GB minimum (8 GB recommended) |
| **Disk Space** | 15 GB free space |
| **Privileges** | Root / Sudo access |
| **Network** | Active internet connection |

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone [https://github.com/nydra-company/nydra-os-builder.git](https://github.com/nydra-company/nydra-os-builder.git)
cd nydra-os-builder
```

### 2. Make Scripts Executable

```bash
chmod +x install-deps.sh build.sh
```

### 3. Run Pre-Flight Check & Install Dependencies

The `install-deps.sh` script verifies disk space, RAM, network connectivity, and installs all required host packages (`live-build`, `xorriso`, `debootstrap`, etc.).

```bash
sudo ./install-deps.sh
```

### 4. Build the ISO Image

Run the build script to configure the root filesystem, inject Nydra OS branding assets, and compile the final ISO.

```bash
sudo ./build.sh
```

Upon completion, your live hybrid ISO image will be generated inside the build directory:
`nydra-os/live-image-amd64.hybrid.iso`

---

## 🛠️ System Overview

- **Base Distribution:** Debian 12 (Bookworm)
- **Desktop Environment:** GNOME (Optimized Core)
- **GTK Theme:** Obsidian-2-Aqua
- **Icon Theme:** Numix-Circle
- **System Colors:** Accent dark (`#3d3b3a`)
- **System Installer:** Calamares
- **Boot Splash:** Custom Plymouth Theme
- **Target Hardware:** UEFI & Legacy BIOS (x86_64)

---

## 📂 Repository Structure

```text
nydra-os-builder/
├── install-deps.sh   # System dependency & pre-flight checker
├── build.sh          # Primary live-build automation script
├── README.md         # Documentation
└── LICENSE           # License agreement
```

---

## 🔗 Official Links

- **Website:** [Nydra OS Web](https://nydra-company.github.io/nydra-web/)
- **GitHub Organization:** [Nydra Company](https://github.com/nydra-company)