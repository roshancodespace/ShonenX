#!/bin/bash

# ShonenX Installer Script
# Author: Darkx-dev
# support: Arch, Debian/Ubuntu, Fedora

set -e

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

LOG_FILE="/tmp/shonenx_install.log"

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check for sudo
if [ "$EUID" -eq 0 ]; then
    warning "Running as root is not recommended specifically for the extraction part, but we will proceed carefully." || true
fi

# -------------------------------------------------------------------------
# Configuration & Directories
# -------------------------------------------------------------------------

INSTALL_DIR="$HOME/.local/share/ShonenX"
ICON_DIR="$HOME/.local/share/icons"
DESKTOP_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"
VERSION_FILE="$INSTALL_DIR/version"
REPO="Darkx-dev/ShonenX"

# -------------------------------------------------------------------------
# Uninstall Function
# -------------------------------------------------------------------------

uninstall() {
    log "Uninstalling ShonenX..."
    rm -rf "$INSTALL_DIR"
    rm -f "$ICON_DIR/shonenx.png"
    rm -f "$DESKTOP_DIR/shonenx.desktop"
    rm -f "$BIN_DIR/shonenx"
    success "Uninstallation complete."
    exit 0
}

if [ "$1" == "--uninstall" ]; then
    uninstall
fi

log "Starting ShonenX Installation..."

# -------------------------------------------------------------------------
# 1. OS Detection & Dependency Installation
# -------------------------------------------------------------------------

log "Detecting OS and checking dependencies..."

install_mpv() {
    log "Installing libmpv..."
    if command -v apt &> /dev/null; then
        # Debian/Ubuntu
        sudo apt update -y | tee -a "$LOG_FILE"
        sudo apt install -y libmpv-dev curl unzip | tee -a "$LOG_FILE"
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        sudo pacman -Sy --noconfirm mpv curl unzip | tee -a "$LOG_FILE"
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf install -y mpv-libs-devel curl unzip | tee -a "$LOG_FILE"
    else
        warning "Could not detect package manager (apt, pacman, dnf). Please ensure 'libmpv', 'curl', and 'unzip' are installed manually."
    fi
}

# Install dependencies
install_mpv

# -------------------------------------------------------------------------
# 2. Version Check
# -------------------------------------------------------------------------

check_version() {
    log "Checking for updates..."
    
    # Get latest version tag from GitHub
    LATEST_VERSION=$(curl -sI "https://github.com/$REPO/releases/latest" | grep -i "location:" | sed 's/.*\///' | tr -d '\r')
    
    if [ -f "$VERSION_FILE" ]; then
        CURRENT_VERSION=$(cat "$VERSION_FILE")
        log "Current version: $CURRENT_VERSION"
        log "Latest version: $LATEST_VERSION"
        
        if [ "$CURRENT_VERSION" == "$LATEST_VERSION" ]; then
            echo -ne "${YELLOW}[?]${NC} You are already on the latest version ($CURRENT_VERSION). Force re-install? [y/N]: "
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log "Installation cancelled by user."
                exit 0
            fi
        fi
    else
        log "Installing version: $LATEST_VERSION"
    fi
    
    # Export for next steps
    TARGET_VERSION="$LATEST_VERSION"
}

check_version

# -------------------------------------------------------------------------
# 3. Download & Extract
# -------------------------------------------------------------------------

LATEST_RELEASE_URL="https://github.com/$REPO/releases/latest/download/ShonenX-Linux.zip"
ICON_URL="https://raw.githubusercontent.com/$REPO/main/assets/icons/app_icon-modified-2.png"

TMP_ZIP="/tmp/ShonenX-Linux.zip"

mkdir -p "$INSTALL_DIR"
mkdir -p "$ICON_DIR"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$BIN_DIR"

log "Downloading latest release from $LATEST_RELEASE_URL..."
if curl -L -o "$TMP_ZIP" "$LATEST_RELEASE_URL" --progress-bar; then
    success "Download complete."
else
    error "Failed to download ShonenX. Please check your internet connection or if the release exists."
fi

log "Extracting to $INSTALL_DIR..."
# Clean old installation
rm -rf "$INSTALL_DIR"/*

unzip -o -q "$TMP_ZIP" -d "$INSTALL_DIR" >> "$LOG_FILE" 2>&1
rm -f "$TMP_ZIP"
echo "$TARGET_VERSION" > "$VERSION_FILE"

# -------------------------------------------------------------------------
# 4. Icon & Desktop Entry
# -------------------------------------------------------------------------

log "Setting up icon and desktop entry..."

# Download Icon
rm -f "$ICON_DIR/shonenx.png" # Force remove old icon
curl -L -o "$ICON_DIR/shonenx.png" "$ICON_URL" >> "$LOG_FILE" 2>&1

# Create Desktop File
cat > "$DESKTOP_DIR/shonenx.desktop" <<EOF
[Desktop Entry]
Name=ShonenX
Comment=Anime Streaming App
Exec=$INSTALL_DIR/shonenx
Icon=$ICON_DIR/shonenx.png
Terminal=false
Type=Application
Categories=Video;AudioVideo;Player;
Keywords=anime;streaming;
StartupWMClass=shonenx
EOF

chmod +x "$DESKTOP_DIR/shonenx.desktop"
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

# CLI Access
log "Creating command line shortcut..."
ln -sf "$INSTALL_DIR/shonenx" "$BIN_DIR/shonenx"

# -------------------------------------------------------------------------
# 5. Finish
# -------------------------------------------------------------------------

success "ShonenX installed successfully!"
echo -e "You can launch it from your application menu or by running 'shonenx' in the terminal."
echo -e "Note: Ensure $HOME/.local/bin is in your PATH."
