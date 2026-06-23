#!/usr/bin/env bash
# ShonenX Universal Linux Installer / Uninstaller
# Author: Roshan Kumar (roshancodespace)

set -e

# Configuration
REPO="roshancodespace/ShonenX"
INSTALL_DIR="$HOME/.local/share/ShonenX"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
ICON_URL="https://raw.githubusercontent.com/roshancodespace/shonenx/main/assets/icons/app_icon-modified-2.png"
EXECUTABLE_NAME="shonenx"
DESKTOP_FILE="shonenx.desktop"

# Colors for UI
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${GREEN}        ShonenX Linux Manager          ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Ensure required commands
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Error: curl is required but not installed.${NC}"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo -e "${RED}Error: jq is required but not installed. Please install jq first.${NC}"; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo -e "${RED}Error: unzip is required but not installed. Please install unzip first.${NC}"; exit 1; }

install_app() {
    echo -e "${YELLOW}[1/5] Fetching latest release info...${NC}"
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
    
    DOWNLOAD_URL=$(echo "$LATEST_RELEASE" | jq -r '.assets[] | select(.name=="linux-bundle.zip") | .browser_download_url')
    VERSION_TAG=$(echo "$LATEST_RELEASE" | jq -r '.tag_name')

    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
        echo -e "${RED}Error: Could not find 'linux-bundle.zip' in the latest release ($VERSION_TAG).${NC}"
        exit 1
    fi

    echo -e "${GREEN}Found Version $VERSION_TAG${NC}"
    
    echo -e "${YELLOW}[2/5] Downloading Linux bundle...${NC}"
    TEMP_ZIP="/tmp/shonenx_linux_bundle.zip"
    curl -L --progress-bar "$DOWNLOAD_URL" -o "$TEMP_ZIP"

    echo -e "${YELLOW}[3/5] Extracting to $INSTALL_DIR...${NC}"
    mkdir -p "$INSTALL_DIR"
    # Clear old install if it exists to avoid conflicts
    rm -rf "$INSTALL_DIR"/*
    unzip -q -o "$TEMP_ZIP" -d "$INSTALL_DIR"
    rm "$TEMP_ZIP"

    # Some zip bundles extract into a subfolder, let's find the executable
    ACTUAL_EXE=$(find "$INSTALL_DIR" -type f -name "$EXECUTABLE_NAME" | head -n 1)
    
    if [ -z "$ACTUAL_EXE" ]; then
        echo -e "${RED}Error: Could not find executable '$EXECUTABLE_NAME' inside the extracted files.${NC}"
        exit 1
    fi

    chmod +x "$ACTUAL_EXE"

    echo -e "${YELLOW}[4/5] Setting up system paths...${NC}"
    mkdir -p "$BIN_DIR"
    ln -sf "$ACTUAL_EXE" "$BIN_DIR/$EXECUTABLE_NAME"

    # Add ~/.local/bin to PATH if not already present
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "${YELLOW}Note: $BIN_DIR is not in your PATH. You may need to add it to your ~/.bashrc or ~/.zshrc${NC}"
    fi

    echo -e "${YELLOW}[5/5] Creating Desktop Entry & Icon...${NC}"
    mkdir -p "$ICON_DIR"
    curl -sL "$ICON_URL" -o "$ICON_DIR/shonenx.png" || echo -e "${RED}Failed to download icon, using fallback.${NC}"

    mkdir -p "$DESKTOP_DIR"
    cat <<EOF > "$DESKTOP_DIR/$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Name=ShonenX
Comment=Anilist & MAL Client for Anime and Manga
Exec=$BIN_DIR/$EXECUTABLE_NAME
Icon=$ICON_DIR/shonenx.png
Terminal=false
Type=Application
Categories=Network;Entertainment;
EOF

    # Update desktop database if possible
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true

    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}   Installation Completed Successfully!${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo -e "You can now launch ShonenX from your application menu,"
    echo -e "or by typing '${BLUE}shonenx${NC}' in your terminal."
}

uninstall_app() {
    echo -e "${YELLOW}Starting Uninstallation...${NC}"

    echo "Removing Installation Directory ($INSTALL_DIR)..."
    rm -rf "$INSTALL_DIR"

    echo "Removing Executable Symlink ($BIN_DIR/$EXECUTABLE_NAME)..."
    rm -f "$BIN_DIR/$EXECUTABLE_NAME"

    echo "Removing Desktop Entry ($DESKTOP_DIR/$DESKTOP_FILE)..."
    rm -f "$DESKTOP_DIR/$DESKTOP_FILE"

    echo "Removing App Icon ($ICON_DIR/shonenx.png)..."
    rm -f "$ICON_DIR/shonenx.png"

    # Update desktop database if possible
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true

    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}   Uninstallation Completed!           ${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo -e "All ShonenX system files have been removed."
    echo -e "Note: User data/cache in ~/.config or ~/.local/share/shonenx_data is preserved."
}

echo "Please select an option:"
echo -e "  ${GREEN}[1] Install / Update ShonenX${NC}"
echo -e "  ${RED}[2] Uninstall ShonenX${NC}"
echo "  [3] Exit"
echo ""

read -p "Selection (1-3): " choice

case $choice in
    1)
        install_app
        ;;
    2)
        read -p "Are you sure you want to uninstall ShonenX? (y/N): " confirm
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            uninstall_app
        else
            echo "Uninstallation cancelled."
        fi
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid selection.${NC}"
        exit 1
        ;;
esac
