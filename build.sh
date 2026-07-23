#!/bin/bash
# ==============================================================================
# Nydra OS 1.0 - Production-Grade Live-Build System (All-In-One Fix)
# Copyright (c) Nydra Company
# Target Base: Debian x86_64 (Bookworm)
# ==============================================================================

set -e

# Ensure root execution
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run as root (use: sudo ./build.sh)"
    exit 1
fi

echo "[INFO] Starting Nydra OS hardened build process..."

# Build environment setup
BUILD_DIR="nydra-os"
mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

echo "[INFO] Cleaning previous live-build state..."
lb clean --purge || true

echo "[INFO] Configuring live-build parameters..."
lb config \
  --distribution bookworm \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components quiet splash username=Nydra user-fullname=Nydra hostname=nydra-os"

echo "[INFO] Creating directory tree..."
mkdir -p config/includes.chroot/etc/firefox/policies/
mkdir -p config/includes.chroot/etc/sudoers.d/
mkdir -p config/includes.chroot/etc/plymouth/
mkdir -p config/includes.chroot/etc/skel/Desktop/
mkdir -p config/includes.chroot/etc/skel/.config/autostart/
mkdir -p config/includes.chroot/etc/skel/.config/gtk-3.0/
mkdir -p config/includes.chroot/etc/skel/.config/gtk-4.0/
mkdir -p config/includes.chroot/usr/bin/
mkdir -p config/includes.chroot/usr/share/applications/
mkdir -p config/includes.chroot/usr/share/backgrounds/
mkdir -p config/includes.chroot/usr/share/pixmaps/
mkdir -p config/includes.chroot/usr/share/themes/
mkdir -p config/includes.chroot/usr/share/icons/
mkdir -p config/includes.chroot/usr/share/gnome-shell/extensions/
mkdir -p config/includes.chroot/usr/share/plymouth/themes/nydra/
mkdir -p config/includes.chroot/etc/calamares/branding/nydra/
mkdir -p config/includes.chroot/etc/calamares/modules/
mkdir -p config/includes.chroot/etc/gdm3/
mkdir -p config/includes.chroot/etc/dconf/db/local.d/
mkdir -p config/includes.chroot/etc/dconf/profile/
mkdir -p config/package-lists/
mkdir -p config/hooks/live/

# OS Metadata
echo "[INFO] Writing OS release information..."
cat << 'EOF' > config/includes.chroot/etc/os-release
NAME="Nydra OS"
VERSION="1.0"
ID=nydra
ID_LIKE=debian
PRETTY_NAME="Nydra OS 1.0"
HOME_URL="https://nydra.cc/"
SUPPORT_URL="https://nydra.cc/"
BUG_REPORT_URL="https://github.com/nydra-company"
PRIVACY_POLICY_URL="https://nydra.cc/"
BUILD_ID="2026.07"
EOF

# Assets & Branding Downloads
echo "[INFO] Downloading assets..."
wget -q -O config/includes.chroot/usr/share/backgrounds/nydra-wallpaper.jpg "https://raw.githubusercontent.com/nydra-company/nydra-logo/refs/heads/main/expanse.jpg" || true
wget -q -O config/includes.chroot/usr/share/pixmaps/nydra-logo.png "https://raw.githubusercontent.com/nydra-company/nydra-logo/refs/heads/main/Nydra-circle.png" || true
cp config/includes.chroot/usr/share/pixmaps/nydra-logo.png config/includes.chroot/usr/share/plymouth/themes/nydra/nydra-logo.png || true

# Themes & Icons Setup
echo "[INFO] Fetching GTK themes and icon packs..."
TMP_DIR=$(mktemp -d)

git clone --depth 1 https://github.com/madmaxms/theme-obsidian-2.git "$TMP_DIR/obsidian" || true
if [ -d "$TMP_DIR/obsidian/Obsidian-2-Aqua" ]; then
    cp -r "$TMP_DIR/obsidian/Obsidian-2-Aqua" config/includes.chroot/usr/share/themes/
elif [ -d "$TMP_DIR/obsidian" ]; then
    cp -r "$TMP_DIR/obsidian" config/includes.chroot/usr/share/themes/Obsidian-2-Aqua
fi

git clone --depth 1 https://github.com/numixproject/numix-icon-theme.git "$TMP_DIR/numix" || true
git clone --depth 1 https://github.com/numixproject/numix-icon-theme-circle.git "$TMP_DIR/numix-circle" || true
[ -d "$TMP_DIR/numix/Numix" ] && cp -r "$TMP_DIR/numix/Numix" config/includes.chroot/usr/share/icons/
[ -d "$TMP_DIR/numix-circle/Numix-Circle" ] && cp -r "$TMP_DIR/numix-circle/Numix-Circle" config/includes.chroot/usr/share/icons/

rm -rf "$TMP_DIR"

# Nydra Welcome GUI Application
echo "[INFO] Creating Nydra Welcome app..."
cat << 'EOF' > config/includes.chroot/usr/bin/nydra-welcome
#!/usr/bin/env python3
import sys
import subprocess
import gi
try:
    gi.require_version('Gtk', '4.0')
    gi.require_version('Adw', '1')
    from gi.repository import Gtk, Adw, Gio
except Exception:
    sys.exit(0)

class WelcomeWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_default_size(680, 520)
        self.set_title("Welcome to Nydra OS")

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        main_box.set_margin_top(24)
        main_box.set_margin_bottom(24)
        main_box.set_margin_start(24)
        main_box.set_margin_end(24)

        logo = Gtk.Image.new_from_file("/usr/share/pixmaps/nydra-logo.png")
        logo.set_pixel_size(96)
        main_box.append(logo)

        title = Gtk.Label(label="Welcome to Nydra OS 1.0")
        title.add_css_class("title-1")
        main_box.append(title)

        subtitle = Gtk.Label(label="Thank you for installing Nydra OS! Here are some quick links to help you get started.")
        subtitle.add_css_class("body")
        subtitle.set_wrap(True)
        subtitle.set_justify(Gtk.Justification.CENTER)
        main_box.append(subtitle)

        grid = Gtk.Grid()
        grid.set_column_spacing(12)
        grid.set_row_spacing(12)
        grid.set_halign(Gtk.Align.CENTER)
        grid.set_margin_top(16)

        btn_web = Gtk.Button(label="🌐 Visit Website")
        btn_web.connect("clicked", lambda x: subprocess.Popen(["xdg-open", "https://nydra.cc/"]))
        grid.attach(btn_web, 0, 0, 1, 1)

        btn_settings = Gtk.Button(label="⚙️ System Settings")
        btn_settings.connect("clicked", lambda x: subprocess.Popen(["gnome-control-center"]))
        grid.attach(btn_settings, 1, 0, 1, 1)

        btn_software = Gtk.Button(label="📦 Software Center")
        btn_software.connect("clicked", lambda x: subprocess.Popen(["gnome-software"]))
        grid.attach(btn_software, 0, 1, 1, 1)

        btn_term = Gtk.Button(label="💻 Open Terminal")
        btn_term.connect("clicked", lambda x: subprocess.Popen(["kitty"]))
        grid.attach(btn_term, 1, 1, 1, 1)

        main_box.append(grid)

        btn_close = Gtk.Button(label="Get Started")
        btn_close.add_css_class("suggested-action")
        btn_close.add_css_class("pill")
        btn_close.set_halign(Gtk.Align.CENTER)
        btn_close.set_margin_top(20)
        btn_close.connect("clicked", lambda x: self.close())
        main_box.append(btn_close)

        self.set_content(main_box)

class WelcomeApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.nydra.welcome", flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_activate(self):
        win = WelcomeWindow(application=self)
        win.present()

if __name__ == "__main__":
    app = WelcomeApp()
    app.run(sys.argv)
EOF

chmod +x config/includes.chroot/usr/bin/nydra-welcome

# Welcome Launcher File
cat << 'EOF' > config/includes.chroot/usr/share/applications/nydra-welcome.desktop
[Desktop Entry]
Type=Application
Name=Nydra Welcome
Comment=Welcome application for new Nydra OS users
Exec=nydra-welcome
Icon=/usr/share/pixmaps/nydra-logo.png
Terminal=false
Categories=System;Utility;
EOF

# First-Boot Autostart for New Users Only
cat << 'EOF' > config/includes.chroot/etc/skel/.config/autostart/nydra-welcome.desktop
[Desktop Entry]
Type=Application
Name=Nydra Welcome
Exec=sh -c "if [ \"$USER\" != \"Nydra\" ]; then nydra-welcome; fi"
Icon=/usr/share/pixmaps/nydra-logo.png
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

chmod +x config/includes.chroot/etc/skel/.config/autostart/nydra-welcome.desktop

# Firefox Policies
echo "[INFO] Setting Firefox policies..."
cat << 'EOF' > config/includes.chroot/etc/firefox/policies/policies.json
{
  "policies": {
    "Homepage": {
      "URL": "https://nydra.cc/",
      "Locked": false,
      "StartPage": "homepage"
    },
    "NewTabURL": "https://nydra.cc/",
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "DontCheckDefaultBrowser": true,
    "DisplayBookmarksToolbar": "never",
    "SearchBar": "unified",
    "EnableTrackingProtection": {
      "Value": true,
      "Locked": false,
      "Cryptomining": true,
      "Fingerprinting": true
    }
  }
}
EOF
chmod 644 config/includes.chroot/etc/firefox/policies/policies.json

# System-wide Dconf Desktop Overrides
echo "[INFO] Applying global dconf configurations..."
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
enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'arcmenu@arcmenu.com', 'gsconnect@andyholmes.github.io', 'ding@rastersoft.com']
EOF

# GTK Global Dark Accents
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

# Plymouth Configuration
echo "[INFO] Configuring Plymouth boot theme..."
cat << 'EOF' > config/includes.chroot/etc/plymouth/plymouthd.conf
[Daemon]
Theme=nydra
ShowDelay=0
DeviceTimeout=8
EOF

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

# GDM3 Auto-Login Configuration
echo "[INFO] Setting up GDM3 auto-login..."
cat << 'EOF' > config/includes.chroot/etc/gdm3/daemon.conf
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=Nydra
TimedLoginEnable=true
TimedLogin=Nydra
TimedLoginDelay=0
EOF

# Sudo Permissions for Live User
echo "Nydra ALL=(ALL) NOPASSWD: ALL" > config/includes.chroot/etc/sudoers.d/nydra-live
chmod 0440 config/includes.chroot/etc/sudoers.d/nydra-live

# Desktop Shortcuts
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
URL=https://nydra.cc/
Icon=/usr/share/pixmaps/nydra-logo.png
EOF

chmod +x config/includes.chroot/etc/skel/Desktop/*.desktop || true

# Calamares Branding & Modules Setup
echo "[INFO] Setting up Calamares installer..."
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
    supportUrl:          "https://nydra.cc/"

images:
    productLogo:          "/usr/share/pixmaps/nydra-logo.png"
    productIcon:          "/usr/share/pixmaps/nydra-logo.png"

slideshow:                "show.qml"
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

# Module 1: Calamares & Live Utilities Self-Destruction
cat << 'EOF' > config/includes.chroot/etc/calamares/modules/packages.conf
---
backend: apt
skip_if_no_change: true
update_db: false

purge:
  - calamares
  - calamares-settings-debian
  - live-boot
  - live-boot-initramfs-tools
  - live-config
  - live-config-systemd
  - live-tools
EOF

# Module 2: Live User Clean Purge
cat << 'EOF' > config/includes.chroot/etc/calamares/modules/removeuser.conf
---
username: Nydra
EOF

# Calamares Execution Sequence
cat << 'EOF' > config/includes.chroot/etc/calamares/settings.conf
---
modules-search: [ local ]

instances:
- id:        nydra
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
  - removeuser
  - packages
  - umount
- show:
  - finished

branding: nydra
prompt-at-end: true
EOF

# Complete Package Manifest
echo "[INFO] Creating Package Manifest..."
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

# Nydra Welcome GUI Stack
python3
python3-gi
gir1.2-gtk-4.0
gir1.2-adw-1
gnome-software

# GNOME Base Utils & Extension Support
gnome-shell-extensions
gnome-shell-extension-prefs
chrome-gnome-shell
gnome-tweaks

# Live System & Installer
calamares
calamares-settings-debian
qml-module-qtquick2
qml-module-qtquick-controls
squashfs-tools
live-boot
live-config
live-config-systemd

# Bootloader & Kernel Tools
plymouth
plymouth-themes
grub-common
grub-pc-bin
grub-efi-amd64-bin
efibootmgr

# User Applications
firefox-esr
kitty
nautilus
eog
gedit
gnome-calculator
gnome-system-monitor

# Drivers & Hardware Firmwares
firmware-linux
firmware-linux-nonfree
firmware-realtek
firmware-iwlwifi
firmware-atheros

# Build Tools
sudo
git
curl
wget
flatpak
p7zip-full
unzip
neofetch
gettext
make
meson
ninja-build
sassc
libglib2.0-dev
EOF

# Chroot Hook (Safe Password Setup + Extension Clones & Schema Compilation)
echo "[INFO] Registering Chroot Hook..."
cat << 'EOF' > config/hooks/live/0090-nydra-system-setup.hook.chroot
#!/bin/sh
set -e

# Fix Password for Live User (Username: Nydra, Password: live)
if id "Nydra" >/dev/null 2>&1; then
    echo "Nydra:live" | chpasswd
else
    useradd -m -s /bin/bash Nydra || true
    echo "Nydra:live" | chpasswd
fi

EXT_DIR="/usr/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"
TMP_BUILD=$(mktemp -d)

clone_ext() {
    REPO="$1"
    TARGET_NAME="$2"
    
    git clone --depth 1 "$REPO" "$TMP_BUILD/repo" || return 0
    if [ -d "$TMP_BUILD/repo/$TARGET_NAME" ]; then
        cp -r "$TMP_BUILD/repo/$TARGET_NAME" "$EXT_DIR/"
    elif [ -f "$TMP_BUILD/repo/metadata.json" ]; then
        cp -r "$TMP_BUILD/repo" "$EXT_DIR/$TARGET_NAME"
    fi
    rm -rf "$TMP_BUILD/repo"
}

# Fetch Extensions
clone_ext "https://github.com/aunetx/blur-my-shell.git" "blur-my-shell@aunetx"
clone_ext "https://github.com/micheleg/dash-to-dock.git" "dash-to-dock@micxgx.gmail.com"
clone_ext "https://gitlab.com/arcmenu/ArcMenu.git" "arcmenu@arcmenu.com"
clone_ext "https://github.com/GSConnect/gnome-shell-extension-gsconnect.git" "gsconnect@andyholmes.github.io"
clone_ext "https://gitlab.com/rastersoft/desktop-icons-ng.git" "ding@rastersoft.com"

rm -rf "$TMP_BUILD"

# Compile schemas safely without crashing on duplicates
for ext_schema in "$EXT_DIR"/*/schemas; do
    if [ -d "$ext_schema" ]; then
        cp -n "$ext_schema"/*.xml /usr/share/glib-2.0/schemas/ 2>/dev/null || true
    fi
done

glib-compile-schemas /usr/share/glib-2.0/schemas || true
dconf update || true
EOF

chmod +x config/hooks/live/0090-nydra-system-setup.hook.chroot

# Execute Build
echo "[INFO] Running safe live-build..."
lb build
