#!/usr/bin/env bash

set -euo pipefail

REPO="roshancodespace/ShonenX"
EXE_NAME="shonenx"
ICON_URL="https://raw.githubusercontent.com/roshancodespace/shonenx/main/assets/icons/app_icon-modified-2.png"
INSTALL_DIR="$HOME/.local/share/ShonenX"

# Set paths dynamically
if [ -n "${TERMUX_VERSION:-}" ]; then
    BIN_DIR="$PREFIX/bin"
    DESKTOP_DIR=""
    ICON_DIR=""
else
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

msg() { echo -e "${BLUE}[*] $1${NC}"; }
success() { echo -e "${GREEN}[✓] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

bootstrap_deps() {
    local missing=()
    for cmd in curl jq unzip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    # Install core tools if missing
    if [ ${#missing[@]} -gt 0 ]; then
        msg "Installing missing tools: ${missing[*]}..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y "${missing[@]}"
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Sy --noconfirm "${missing[@]}"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "${missing[@]}"
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper install -y "${missing[@]}"
        elif [ -n "${TERMUX_VERSION:-}" ] && command -v pkg >/dev/null 2>&1; then
            pkg install -y "${missing[@]}"
        else
            error "Install these manually first: ${missing[*]}"
        fi
    fi

    # Check for libmpv / mpv shared library
    local has_mpv=0
    if ldconfig -p 2>/dev/null | grep -q "libmpv"; then has_mpv=1; fi
    if [ -f /usr/lib/libmpv.so ] || [ -f /usr/lib64/libmpv.so ] || [ -f /usr/local/lib/libmpv.so ] || [ -f "${PREFIX:-}/lib/libmpv.so" ]; then 
        has_mpv=1
    fi

    if [ "$has_mpv" -eq 0 ]; then
        msg "libmpv not found. Installing libmpv/mpv fallback..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y libmpv-dev || sudo apt-get install -y mpv
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --noconfirm mpv
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y mpv-libs || sudo dnf install -y mpv
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper install -y libmpv1 || sudo zypper install -y mpv
        elif [ -n "${TERMUX_VERSION:-}" ] && command -v pkg >/dev/null 2>&1; then
            pkg install -y mpv
        else
            warn "Could not auto-install libmpv. Please ensure mpv/libmpv is installed manually."
        fi
    fi
}

setup_path() {
    if [ -n "${TERMUX_VERSION:-}" ] || [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        return
    fi

    warn "$BIN_DIR is not in your PATH."
    read -p "Add it to your shell configurations automatically? (y/N): " add_path
    if [[ "$add_path" =~ ^[yY](es)?$ ]]; then
        [ -f "$HOME/.bashrc" ] && ! grep -q "$BIN_DIR" "$HOME/.bashrc" && echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc" && success "Updated ~/.bashrc"
        [ -f "$HOME/.zshrc" ] && ! grep -q "$BIN_DIR" "$HOME/.zshrc" && echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc" && success "Updated ~/.zshrc"
        
        if [ -d "$HOME/.config/fish" ]; then
            mkdir -p "$HOME/.config/fish"
            touch "$HOME/.config/fish/config.fish"
            if ! grep -q "$BIN_DIR" "$HOME/.config/fish/config.fish"; then
                echo -e "\n# ShonenX Path\nfish_add_path $BIN_DIR" >> "$HOME/.config/fish/config.fish"
                success "Updated ~/.config/fish/config.fish"
            fi
        fi
        warn "Restart your terminal or source your config to apply PATH updates."
    fi
}

install() {
    bootstrap_deps
    
    msg "Checking latest release from GitHub..."
    local release_json
    release_json=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
    
    local download_url
    download_url=$(echo "$release_json" | jq -r '
        .assets[] | 
        select(.name | ascii_downcase | (contains("linux") and endswith(".zip"))) | 
        .browser_download_url
    ' | head -n 1)

    local version
    version=$(echo "$release_json" | jq -r '.tag_name')

    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        error "No linux zip asset found in release $version"
    fi

    success "Found version: $version"
    
    local tmp_zip="/tmp/shonenx.zip"
    msg "Downloading..."
    curl -L --progress-bar "$download_url" -o "$tmp_zip"

    msg "Extracting files..."
    rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR"
    unzip -q -o "$tmp_zip" -d "$INSTALL_DIR"
    rm -f "$tmp_zip"

    # Flatten the directory if files are nested inside a 'linux' folder
    if [ -d "$INSTALL_DIR/linux" ]; then
        find "$INSTALL_DIR/linux" -maxdepth 1 -mindepth 1 -exec mv -t "$INSTALL_DIR" {} +
        rmdir "$INSTALL_DIR/linux"
    fi

    local exe_path
    exe_path=$(find "$INSTALL_DIR" -type f -name "$EXE_NAME" | head -n 1)
    
    if [ -z "$exe_path" ]; then
        error "Executable '$EXE_NAME' not found in archive"
    fi
    chmod +x "$exe_path"

    mkdir -p "$BIN_DIR"
    ln -sf "$exe_path" "$BIN_DIR/$EXE_NAME"

    if [ -n "$DESKTOP_DIR" ]; then
        msg "Creating desktop shortcuts..."
        mkdir -p "$ICON_DIR" "$DESKTOP_DIR"
        curl -sL "$ICON_URL" -o "$ICON_DIR/shonenx.png" || warn "Icon download failed, skipping shortcut icon."

        cat <<EOF > "$DESKTOP_DIR/shonenx.desktop"
[Desktop Entry]
Version=1.0
Name=ShonenX
Comment=Anilist & MAL Client for Anime and Manga
Exec=$BIN_DIR/$EXE_NAME
Icon=$ICON_DIR/shonenx.png
Terminal=false
Type=Application
Categories=Network;Entertainment;
EOF
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
    fi

    setup_path
    success "Done. Run using: $EXE_NAME"
}

uninstall() {
    warn "Removing ShonenX..."
    rm -rf "$INSTALL_DIR"
    rm -f "$BIN_DIR/$EXE_NAME"

    if [ -n "$DESKTOP_DIR" ]; then
        rm -f "$DESKTOP_DIR/shonenx.desktop"
        rm -f "$ICON_DIR/shonenx.png"
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
    fi

    success "Uninstalled successfully. Configuration metrics preserved."
}

echo "ShonenX Launcher Utilities"
echo " 1) Install / Update"
echo " 2) Uninstall"
echo " 3) Exit"
echo ""
read -p "Action [1-3]: " choice

case "$choice" in
    1) install ;;
    2) 
        read -p "Are you sure? (y/N): " confirm
        [[ "$confirm" =~ ^[yY](es)?$ ]] && uninstall || msg "Aborted."
        ;;
    3) exit 0 ;;
    *) error "Invalid selection." ;;
esac
