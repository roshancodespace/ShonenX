#!/bin/bash
set -euo pipefail

# --- Configuration ---
APP_NAME="shonenx"
REPO="Darkx-dev/ShonenX"
INSTALL_DIR="$HOME/.local/share/ShonenX"
BIN_DIR="$HOME/.local/bin"
LOG_FILE="/tmp/shonenx_install.log"
SYS_DESKTOP="/usr/share/applications/$APP_NAME.desktop"
SYS_ICON="/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"

# --- Dark Theme ---
export NEWT_COLORS='
  root=,black
  window=black,black
  border=black,black
  shadow=black,black
  button=black,cyan
  actbutton=white,cyan
  compactbutton=black,cyan
  title=cyan,black
  roottext=cyan,black
  textbox=cyan,black
  actlistbox=black,cyan
  listbox=cyan,black
  checkbox=cyan,black
  actcheckbox=black,cyan
'

# --- Responsive Logic ---
get_size() {
    TERM_WIDTH=$(tput cols || echo 80)
    BOX_WIDTH=$(( TERM_WIDTH * 70 / 100 ))
    [[ $BOX_WIDTH -lt 45 ]] && BOX_WIDTH=45
    BOX_HEIGHT=15
}

# --- Logic Functions ---

pre_auth_sudo() {
    sudo -v
}

task_deps() {
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --needed mpv curl unzip wget desktop-file-utils > "$LOG_FILE" 2>&1
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y -q mpv-libs-devel curl unzip wget desktop-file-utils > "$LOG_FILE" 2>&1
    elif command -v apt &>/dev/null; then
        sudo apt update -qq && sudo apt install -y -qq libmpv-dev curl unzip wget desktop-file-utils > "$LOG_FILE" 2>&1
    fi
}

task_download() {
    mkdir -p "$INSTALL_DIR" "$BIN_DIR"
    TMP_ZIP="/tmp/ShonenX_latest.zip"
    curl -L "https://github.com/$REPO/releases/latest/download/ShonenX-Linux.zip" -o "$TMP_ZIP" 2>> "$LOG_FILE"
    rm -rf "${INSTALL_DIR:?}"/*
    unzip -o -q "$TMP_ZIP" -d "$INSTALL_DIR" >> "$LOG_FILE" 2>&1
    rm -f "$TMP_ZIP"
}

task_normalize() {
    RAW_BIN=$(find "$INSTALL_DIR" -maxdepth 2 -iname "shonenx*" -type f -not -name "*.so*" -not -name "*.txt" -not -name "*.png" | head -n 1)
    if [[ -n "$RAW_BIN" ]]; then
        mv "$RAW_BIN" "$INSTALL_DIR/$APP_NAME"
        chmod +x "$INSTALL_DIR/$APP_NAME"
        ln -sf "$INSTALL_DIR/$APP_NAME" "$BIN_DIR/$APP_NAME"
    else
        return 1
    fi
}

task_ui() {
    sudo mkdir -p "/usr/share/icons/hicolor/256x256/apps"
    sudo wget -qO "$SYS_ICON" "https://raw.githubusercontent.com/$REPO/main/assets/icons/app_icon-modified-2.png" || true
    sudo bash -c "cat <<EOF > $SYS_DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=ShonenX
Comment=Anime Streaming Desktop
Exec=$BIN_DIR/$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=Video;AudioVideo;Player;
StartupWMClass=shonenx
EOF"
    sudo chmod 644 "$SYS_DESKTOP"
    sudo update-desktop-database /usr/share/applications >/dev/null 2>&1
    rm -rf "$HOME/.cache/wofi" "$HOME/.cache/rofi" "$HOME/.cache/fuzzel" 2>/dev/null || true
}

task_path() {
    if [[ "$SHELL" == *"fish"* ]]; then
        fish -c "set -U fish_user_paths $BIN_DIR \$fish_user_paths" >/dev/null 2>&1
    else
        PROFILE="$HOME/.bashrc"
        [[ "$SHELL" == *"zsh"* ]] && PROFILE="$HOME/.zshrc"
        grep -q "$BIN_DIR" "$PROFILE" || echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$PROFILE"
    fi
}

# --- TUI Loop ---

while true; do
    get_size
    STATUS=$( [[ -d "$INSTALL_DIR" ]] && echo "INSTALLED" || echo "NOT FOUND" )

    CHOICE=$(whiptail --title " SHONENX MANAGER [$STATUS] " \
        --menu "\nNavigation: Arrows | Confirm: Enter" \
        $BOX_HEIGHT $BOX_WIDTH 5 \
        "1" "Full Install / Update" \
        "2" "Fix Shortcuts/Menu" \
        "3" "Fix PATH/Terminal" \
        "4" "Nuclear Uninstall" \
        "5" "Exit" 3>&1 1>&2 2>&3) || exit 0

    case $CHOICE in
        1)
            pre_auth_sudo
            { 
              echo 25; task_deps
              echo 50; task_download
              echo 75; task_normalize
              echo 100; task_ui; task_path
            } | whiptail --title " Installing " --gauge "\nProcessing build steps..." 8 $BOX_WIDTH 0
            whiptail --title " Complete " --msgbox "\nShonenX is ready." 8 $BOX_WIDTH
            ;;
        2) 
            pre_auth_sudo; task_ui
            whiptail --title " Fixed " --msgbox "\nDesktop menu rebuilt." 8 $BOX_WIDTH
            ;;
        3) 
            task_path
            whiptail --title " Fixed " --msgbox "\nShell PATH updated." 8 $BOX_WIDTH
            ;;
        4) 
            pre_auth_sudo
            rm -rf "$INSTALL_DIR" && rm -f "$BIN_DIR/$APP_NAME"
            sudo rm -f "$SYS_DESKTOP" "$SYS_ICON"
            sudo update-desktop-database /usr/share/applications >/dev/null 2>&1
            whiptail --title " Wiped " --msgbox "\nAll files removed." 8 $BOX_WIDTH
            ;;
        5) exit 0 ;;
    esac
done