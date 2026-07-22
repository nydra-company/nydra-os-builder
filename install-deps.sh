#!/bin/bash
# ==============================================================================
# Nydra OS - Dependency Installer & System Pre-Flight Checker
# Copyright (c) Nydra Company
# ==============================================================================

set -e

# Color definitions for status output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[INFO] Starting Nydra OS System Pre-Flight Check...${NC}"

# 1. Check Root Privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] This script must be run as root. Use: sudo ./install-deps.sh${NC}"
    exit 1
fi

# 2. Check Host Operating System
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "${BLUE}[INFO] Host OS detected: ${NAME} ${VERSION_ID}${NC}"
    if [[ "$ID" != "debian" && "$ID" != "ubuntu" && "$ID_LIKE" != *"debian"* ]]; then
        echo -e "${YELLOW}[WARNING] Live-build works best on Debian/Ubuntu-based systems.${NC}"
    fi
else
    echo -e "${YELLOW}[WARNING] Could not determine host OS distribution.${NC}"
fi

# 3. Check Available RAM (Minimum 4GB recommended for live-build)
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
echo -e "${BLUE}[INFO] Available RAM: ${TOTAL_RAM} MB${NC}"
if [ "$TOTAL_RAM" -lt 3500 ]; then
    echo -e "${YELLOW}[WARNING] Less than 4GB RAM detected. Building ISO might be slow or run out of memory.${NC}"
fi

# 4. Check Free Disk Space (Minimum 15GB required)
FREE_SPACE=$(df -m . | awk 'NR==2 {print $4}')
FREE_SPACE_GB=$((FREE_SPACE / 1024))
echo -e "${BLUE}[INFO] Available Disk Space: ${FREE_SPACE_GB} GB${NC}"

if [ "$FREE_SPACE_GB" -lt 12 ]; then
    echo -e "${RED}[ERROR] Insufficient disk space! At least 15GB of free space is required to build the ISO.${NC}"
    exit 1
fi

# 5. Check Active Internet Connection
echo -e "${BLUE}[INFO] Checking internet connectivity...${NC}"
if ping -c 1 debian.org >/dev/null 2>&1 || ping -c 1 github.com >/dev/null 2>&1; then
    echo -e "${GREEN}[OK] Internet connection active.${NC}"
else
    echo -e "${RED}[ERROR] No internet connection detected. Active network is required to download packages.${NC}"
    exit 1
fi

# 6. Install Essential Build Dependencies
echo -e "${BLUE}[INFO] Updating package lists and installing required dependencies...${NC}"
apt-get update -q

REQUIRED_PACKAGES=(
    "live-build"
    "git"
    "wget"
    "curl"
    "p7zip-full"
    "debootstrap"
    "squashfs-tools"
    "xorriso"
    "grub-pc-bin"
    "grub-efi-amd64-bin"
)

echo -e "${BLUE}[INFO] Installing packages: ${REQUIRED_PACKAGES[*]}${NC}"
apt-get install -y "${REQUIRED_PACKAGES[@]}"

echo -e "${GREEN}[SUCCESS] All system checks passed and dependencies installed successfully!${NC}"
echo -e "${GREEN}[SUCCESS] Your system is ready to build Nydra OS.${NC}"
echo -e "${BLUE}[NEXT STEP] Run: sudo ./build.sh${NC}"