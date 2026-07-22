#!/bin/bash
# ==============================================================================
# Nydra OS 1.0 - Automated Live-Build System
# Copyright (c) Nydra Company
# Target Base: Debian x86_64
# ==============================================================================

set -e

# Ensure the script is executed with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run as root (use: sudo ./build.sh)"
    exit 1
fi

echo "[INFO] Starting Nydra OS build process..."

# Define build environment
BUILD_DIR="nydra-os"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

# Clean previous build artifacts
echo "[INFO] Cleaning previous live-build state..."
lb clean --purge || true

# Configure live-build framework
echo "[INFO] Configuring live-build architecture and boot parameters..."
lb config \
  --distribution bookworm \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components quiet splash username=Nydra hostname=nydra-os"

# Create root filesystem directory structure
echo "[INFO] Initializing system directory structure..."
mkdir -p config/includes.chroot/etc/
mkdir -p config/includes.chroot/etc/sudoers.d/
mkdir -p config/includes.chroot/etc/skel/Desktop/
mkdir -p config/includes.chroot/etc/skel/.config/gtk-3.0/
mkdir -p config/includes.chroot/etc/skel/.config/gtk-4.0/
mkdir -p config/includes.chroot/usr/share/backgrounds/
mkdir -p config/includes.chroot/usr/share/pixmaps/
mkdir -p config/includes.chroot/usr/share/themes/
mkdir -p config/includes.chroot/usr/share/icons/
mkdir -p config/includes.chroot/usr/share/plymouth/themes/nydra/
mkdir -p config/includes.chroot/etc/calamares/branding/nydra/
mkdir -p config/includes.chroot/etc/calamares/modules/
mkdir -p config/includes.chroot/etc/gdm3/
mkdir -p config/includes.chroot/etc/dconf/db/local.d/
mkdir -p config/includes.chroot/etc/dconf/profile/
mkdir -p config/package-lists/
mkdir -p config/hooks/live/

# Configure OS release parameters
echo "[INFO] Writing system release metadata..."
cat << 'EOF' > config/includes.chroot/etc/os-release
NAME="Nydra OS"
VERSION="1.0"
ID=nydra
ID_LIKE=debian
PRETTY_NAME="Nydra OS 1.0"
HOME_URL="https://nydra-company.github.io/nydra-web/"
SUPPORT_URL="https://nydra-company.github.io/nydra-web/"
BUG_REPORT_URL="https://github.com/nydra-company"
PRIVACY_POLICY_URL="https://nydra-company.github.io/nydra-web/"
BUILD_ID="2026.07"
EOF

# Fetch official branding assets
echo "[INFO] Downloading official branding assets..."
wget -q -O config/includes.chroot/usr/share/backgrounds/nydra-wallpaper.jpg "https://raw.githubusercontent.com/nydra-company/nydra-logo/refs/heads/main/expanse.jpg"
wget -q -O config/includes.chroot/usr/share/pixmaps/nydra-logo.png "https://raw.githubusercontent.com/nydra-company/nydra-logo/refs/heads/main/Nydra-circle.png"
cp config/includes.chroot/usr/share/pixmaps/nydra-logo.png config/includes.chroot/usr/share/plymouth/themes/nydra/nydra-logo.png

# Fetch desktop themes and icon sets
echo "[INFO] Fetching GTK theme and icon resources..."
TMP_DIR=$(mktemp -d)

git clone --depth 1 https://github.com/madmaxms/theme-obsidian-2.git "$TMP_DIR/obsidian" || true
if [ -d "$TMP_DIR/obsidian/Obsidian-2-Aqua" ]; then
    cp -r "$TMP_DIR/obsidian/Obsidian-2-Aqua" config/includes.chroot/usr/share/themes/
elif [ -d "$TMP_DIR/obsidian" ]; then
    cp -r "$TMP_DIR/obsidian" config/includes.chroot/usr/share/themes/Obsidian-2-Aqua
fi

git clone --depth 1 https://github.com/numixproject/numix-icon-theme.git "$TMP_DIR/numix"
git clone --depth 1 https://github.com/numixproject/numix-icon-theme-circle.git "$TMP_DIR/numix-circle"
cp -r "$TMP_DIR/numix/Numix" config/includes.chroot/usr/share/icons/
cp -r "$TMP_DIR/numix-circle/Numix-Circle" config/includes.chroot/usr/share/icons/

rm -rf "$TMP_DIR"

# Configure default system theme via dconf overrides
echo "[INFO] Applying global dconf desktop configurations..."
cat << 'EOF' > config/includes.chroot/etc/dconf/profile/user
user-db:user
system-db:local
EOF

cat << 'EOF' > config/includes.chroot/etc/dconf/db/local.d/00-nydra-theme
[org/gnome/desktop/interface]
gtk-theme='Obsidian-2-Aqua'
icon-theme='Numix-Circle'
color-scheme='prefer-dark'
font-name='Sans 11'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/nydra-wallpaper.jpg'
picture-uri-dark='file:///usr/share/backgrounds/nydra-wallpaper.jpg'
picture-options='zoom'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/nydra-wallpaper.jpg'

[org/gnome/desktop/wm/preferences]
theme='Obsidian-2-Aqua'

[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'arcmenu@arcmenu.com', 'gsconnect@andyholmes.github.io', 'ding@rastersoft.com', 'ubuntu-appindicators@ubuntu.com']
EOF

# Inject custom color schemes into GTK definitions
echo "[INFO] Injecting custom color scheme definitions..."
cat << 'EOF' | tee config/includes.chroot/etc/skel/.config/gtk-3.0/gtk.css > config/includes.chroot/etc/skel/.config/gtk-4.0/gtk.css
@define-color theme_bg_color #3d3b3a;
@define-color theme_fg_color #ffffff;
@define-color theme_base_color #3d3b3a;
@define-color theme_text_color #ffffff;
@define-color theme_selected_bg_color #575452;
@define-color theme_selected_fg_color #ffffff;

window.background {
    background-color: #3d3b3a;
    color: #ffffff;
}

label, entry, textarea {
    color: #ffffff;
}
EOF

# Setup Plymouth boot splash screen
echo "[INFO] Setting up Plymouth boot splash configuration..."
cat << 'EOF' > config/includes.chroot/usr/share/plymouth/themes/nydra/nydra.plymouth
[Plymouth Theme]
Name=Nydra OS Boot
Description=Official Plymouth theme for Nydra OS
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/nydra
ScriptFile=/usr/share/plymouth/themes/nydra/nydra.script
EOF

cat << 'EOF' > config/includes.chroot/usr/share/plymouth/themes/nydra/nydra.script
logo.image = Image("nydra-logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetX(Window.GetWidth() / 2 - logo.image.GetWidth() / 2);
logo.sprite.SetY(Window.GetHeight() / 2 - logo.image.GetHeight() / 2);

Window.SetBackgroundTopColor(0.24, 0.23, 0.22);
Window.SetBackgroundBottomColor(0.24, 0.23, 0.22);
EOF

# Configure Display Manager and Live User privileges
echo "[INFO] Setting up auto-login and user environment..."
cat << 'EOF' > config/includes.chroot/etc/gdm3/daemon.conf
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=Nydra
EOF

echo "Nydra ALL=(ALL) NOPASSWD: ALL" > config/includes.chroot/etc/sudoers.d/nydra-live
chmod 0440 config/includes.chroot/etc/sudoers.d/nydra-live

# Generate default desktop entries
cat << 'EOF' > config/includes.chroot/etc/skel/Desktop/install-nydra.desktop
[Desktop Entry]
Type=Application
Name=Install Nydra OS
Comment=Install Nydra OS to your computer
Exec=sudo calamares
Icon=/usr/share/pixmaps/nydra-logo.png
Terminal=false
Categories=System;
EOF

cat << 'EOF' > config/includes.chroot/etc/skel/Desktop/nydra-website.desktop
[Desktop Entry]
Type=Link
Name=Nydra Website
URL=https://nydra-company.github.io/nydra-web/
Icon=/usr/share/pixmaps/nydra-logo.png
EOF

chmod +x config/includes.chroot/etc/skel/Desktop/*.desktop

# Configure Calamares installer environment & slideshow
echo "[INFO] Configuring Calamares system installer branding..."
cat << 'EOF' > config/includes.chroot/etc/calamares/branding/nydra/branding.desc
---
componentName:  nydra

welcomeStyleCalamares: true
welcomeExpandingLogo: true

strings:
    productName:         Nydra OS
    shortProductName:    Nydra
    version:             1.0
    shortVersion:        1.0
    versionedName:       Nydra OS 1.0
    shortVersionedName:  Nydra 1.0
    sidebar:             Nydra OS
    navigation:          Installer
    supportUrl:          "https://nydra-company.github.io/nydra-web/"

images:
    productLogo:         "/usr/share/pixmaps/nydra-logo.png"
    productIcon:         "/usr/share/pixmaps/nydra-logo.png"

slideshow:               "show.qml"
slideshowAPI:            2

style:
   SidebarBackground:    "#3d3b3a"
   SidebarText:          "#ffffff"
   SidebarTextSelect:    "#ffffff"
   SidebarTextHighlight: "#ffffff"
EOF

cat << 'EOF' > config/includes.chroot/etc/calamares/branding/nydra/show.qml
import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Slide {
        Text {
            anchors.centerIn: parent
            text: "Welcome to Nydra OS 1.0"
            font.pixelSize: 24
            color: "#ffffff"
        }
    }
}
EOF

cat << 'EOF' > config/includes.chroot/etc/calamares/settings.conf
---
modules-search: [ local ]

instances:
- id:       nydra
  module:    branding
  config:    branding.desc

sequence:
- show:
  - welcome
  - locale
  - keyboard
  - partition
  - users
  - summary
- exec:
  - partition
  - mount
  - unpackfs
  - machineid
  - fstab
  - locale
  - keyboard
  - localecfg
  - users
  - displaymanager
  - networkcfg
  - hwclock
  - grubcfg
  - bootloader
  - umount
- show:
  - finished

branding: nydra
prompt-at-end: true
EOF

# Define target package manifests
echo "[INFO] Generating system package manifest..."
cat << 'EOF' > config/package-lists/nydra.list.chroot
# Core Desktop System
gnome-core
gdm3
network-manager-gnome
pipewire
pipewire-audio
wireplumber
gtk2-engines-murrine
gtk2-engines-pixbuf
dconf-cli
dconf-editor

# GNOME Extensions Packages
gnome-shell-extensions
gnome-shell-extension-dashtodock
gnome-shell-extension-blur-my-shell
gnome-shell-extension-arc-menu
gnome-shell-extension-gsconnect
gnome-shell-extension-desktop-icons-ng
gnome-shell-extension-appindicator
gnome-shell-extension-gpaste
gnome-shell-extension-prefs

# Live System & Installer Infrastructure
calamares
calamares-settings-debian
qml-module-qtquick2
qml-module-qtquick-controls
squashfs-tools
live-boot
live-config
live-config-systemd

# Boot & Hardware Components
plymouth
plymouth-themes
grub-common
grub-pc-bin
grub-efi-amd64-bin
efibootmgr
gnome-tweaks

# User Utilities
firefox-esr
kitty
nautilus
eog
gedit
gnome-calculator
gnome-system-monitor

# Hardware Firmwares
firmware-linux
firmware-linux-nonfree
firmware-realtek
firmware-iwlwifi
firmware-atheros

# System Tooling
sudo
git
curl
wget
flatpak
p7zip-full
unzip
neofetch
EOF

# System initialization hooks inside chroot
echo "[INFO] Creating post-install chroot setup hooks..."
cat << 'EOF' > config/hooks/live/0090-nydra-system-setup.hook.chroot
#!/bin/sh
set -e

# Update dconf database for theme and extensions
dconf update || true

# Enable default plymouth theme
plymouth-set-default-theme -R nydra || true

# Setup live user
useradd -m -s /bin/bash -g sudo Nydra || true
echo "Nydra:nydra" | chpasswd

chmod +x /etc/skel/Desktop/*.desktop || true
glib-compile-schemas /usr/share/glib-2.0/schemas
EOF

chmod +x config/hooks/live/0090-nydra-system-setup.hook.chroot

# Execute live image build
echo "[INFO] All configurations successfully initialized."
echo "[INFO] Initiating image creation process..."

lb build
