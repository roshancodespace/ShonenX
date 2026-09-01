#!/usr/bin/env bash
set -euo pipefail

# always restore cursor and exit cleanly if user hits Ctrl+C
trap 'tput cnorm 2>/dev/null || true; echo -e "\n\033[31m[!] Installation aborted.\033[0m"; exit 130' INT TERM

# defaults
DEFAULT_REPO="roshancodespace/ShonenX"
EXE_NAME="shonenx"
DEFAULT_ICON_URL="https://raw.githubusercontent.com/roshancodespace/shonenx/main/assets/images/app_icon.png"
DEFAULT_INSTALL_DIR="$HOME/.local/share/ShonenX"
CACHE_DIR="$HOME/.config/ShonenX"
CACHE_FILE="$CACHE_DIR/installer.cache"

REPO="$DEFAULT_REPO"
ICON_INPUT="$DEFAULT_ICON_URL"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
SELECTED_TAG="latest"
CLI_MODE=false
ACTION=""

# load previous settings if they exist
if [ -f "$CACHE_FILE" ]; then
    source "$CACHE_FILE" 2>/dev/null || true
fi

# figure out paths depending on if we are on termux or normal linux
IS_TERMUX=false
SUDO="sudo"
if [ -n "${TERMUX_VERSION:-}" ]; then
    IS_TERMUX=true; SUDO=""
    BIN_DIR="$PREFIX/bin"
    DESKTOP_DIR=""
    ICON_DIR=""
else
    command -v sudo >/dev/null 2>&1 || SUDO=""
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
fi

# print helpers
log()  { echo -e "\033[36m[*]\033[0m $1"; }
ok()   { echo -e "\033[32m[+]\033[0m $1"; }
err()  { echo -e "\033[31m[!]\033[0m $1"; }
warn() { echo -e "\033[33m[!]\033[0m $1"; }

save_cache() {
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
    echo "REPO=\"$REPO\"" > "$CACHE_FILE"
    echo "ICON_INPUT=\"$ICON_INPUT\"" >> "$CACHE_FILE"
    echo "INSTALL_DIR=\"$INSTALL_DIR\"" >> "$CACHE_FILE"
}

# dynamically fetch and let user select a github release
fetch_and_select_tag() {
    clear
    log "fetching recent versions from GitHub..."
    local api_url="https://api.github.com/repos/$REPO/releases?per_page=10"
    
    local tags
    tags=$(curl -s "$api_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || true)
    
    if [ -z "$tags" ]; then
        warn "could not fetch versions (network or API limit). defaulting to latest."
        SELECTED_TAG="latest"
        sleep 2
        return
    fi

    echo -e "\n\033[35m--- Select Version ---\033[0m\n"
    
    local tag_array=("latest")
    while read -r line; do
        [ -n "$line" ] && tag_array+=("$line")
    done <<< "$tags"

    for i in "${!tag_array[@]}"; do
        if [ "$i" -eq 0 ]; then
            echo "  [$i] ${tag_array[$i]} (auto-detect newest)"
        else
            echo "  [$i] ${tag_array[$i]}"
        fi
    done
    echo ""
    
    tput cnorm 2>/dev/null || true
    read -rp "  Select a number [0]: " v_idx
    tput civis 2>/dev/null || true

    if [[ "$v_idx" =~ ^[0-9]+$ ]] && [ "$v_idx" -lt "${#tag_array[@]}" ]; then
        SELECTED_TAG="${tag_array[$v_idx]}"
    else
        SELECTED_TAG="latest"
    fi
    
    ok "selected version: $SELECTED_TAG\n"
    sleep 1
}

check_dependencies() {
    log "checking system dependencies..."
    
    local missing=0
    local missing_ffmpeg=0

    # fast check to see if the libraries are already in the system cache
    if ! $IS_TERMUX; then
        ldconfig -p 2>/dev/null | grep -q "libmpv" || missing=1
        ldconfig -p 2>/dev/null | grep -q "libsecret" || missing=1
        ldconfig -p 2>/dev/null | grep -q -i "webkit2gtk\|webkitgtk" || missing=1
    else
        command -v mpv >/dev/null 2>&1 || missing=1
    fi

    command -v ffmpeg >/dev/null 2>&1 || missing_ffmpeg=1
    [ "$missing_ffmpeg" -eq 1 ] && missing=1

    if [ "$missing" -eq 0 ]; then
        ok "all dependencies found."
        return 0
    fi

    warn "missing dependencies. attempting to auto-install..."
    if [ "$missing_ffmpeg" -eq 1 ]; then
        log "Note: ShonenX defaults to FFmpeg for safely remuxing downloaded TS segments."
        log "If skipped, it will fallback to a raw, unsafe stitching method."
    fi
    
    # Show cursor so sudo and pacman prompts are usable
    tput cnorm 2>/dev/null || true 
    echo ""

    local failed=0
    if $IS_TERMUX && command -v pkg >/dev/null 2>&1; then
        pkg install -y mpv ffmpeg || failed=1
    elif command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -qq || true
        $SUDO apt-get install -y libmpv-dev mpv libsecret-1-0 libwebkit2gtk-4.1-0 ffmpeg || failed=1
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -S --needed --noconfirm mpv libsecret webkit2gtk-4.1 ffmpeg || failed=1
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y mpv-libs mpv libsecret webkit2gtk4.1 ffmpeg || failed=1
    elif command -v zypper >/dev/null 2>&1; then
        $SUDO zypper install -y libmpv1 mpv libsecret-1-0 libwebkit2gtk-4_1-0 ffmpeg || failed=1
    else
        failed=1
    fi

    echo ""
    # hide cursor again for the rest of the install process
    tput civis 2>/dev/null || true 

    if [ "$failed" -eq 1 ]; then
        warn "Package manager encountered an error (likely a conflict)."
        warn "Skipping dependency installation. ShonenX may still run fine."
        sleep 2
    else
        ok "dependencies installed."
    fi
    
    return 0
}

setup_path() {
    $IS_TERMUX && return
    [[ ":$PATH:" == *":$BIN_DIR:"* ]] && return

    log "adding $BIN_DIR to PATH in shell configs..."
    [ -f "$HOME/.bashrc" ] && ! grep -q "$BIN_DIR" "$HOME/.bashrc" && echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && ! grep -q "$BIN_DIR" "$HOME/.zshrc" && echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc"
    
    if [ -d "$HOME/.config/fish" ]; then
        touch "$HOME/.config/fish/config.fish"
        ! grep -q "$BIN_DIR" "$HOME/.config/fish/config.fish" && echo -e "\nfish_add_path $BIN_DIR" >> "$HOME/.config/fish/config.fish"
    fi
}

core_install() {
    $CLI_MODE || clear
    check_dependencies

    log "fetching release info for $REPO..."
    local api_url="https://api.github.com/repos/$REPO/releases/latest"
    [ "$SELECTED_TAG" != "latest" ] && api_url="https://api.github.com/repos/$REPO/releases/tags/$SELECTED_TAG"

    local release_json
    release_json=$(curl -s "$api_url")
    if echo "$release_json" | grep -q '"message": "Not Found"'; then
        err "repo or release not found."
        return 1
    fi

    local download_url version
    download_url=$(echo "$release_json" | grep -o '"browser_download_url": "[^"]*' | grep -i "linux" | sed 's/"browser_download_url": "//' | head -n 1)
    version=$(echo "$release_json" | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//' | head -n 1)

    [ -z "$download_url" ] && { err "no linux asset found."; return 1; }

    log "downloading $version..."
    local tmp_zip="/tmp/shonenx.zip"
    
    curl -# -L "$download_url" -o "$tmp_zip"
    
    log "extracting to $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR"
    unzip -q -o "$tmp_zip" -d "$INSTALL_DIR"
    rm -f "$tmp_zip"

    [ -d "$INSTALL_DIR/linux" ] && find "$INSTALL_DIR/linux" -maxdepth 1 -mindepth 1 -exec mv -t "$INSTALL_DIR" {} + && rmdir "$INSTALL_DIR/linux"

    local exe_path
    exe_path=$(find "$INSTALL_DIR" -type f -name "$EXE_NAME" | head -n 1)
    [ -z "$exe_path" ] && { err "binary not found inside zip."; return 1; }

    chmod +x "$exe_path"
    mkdir -p "$BIN_DIR"
    ln -sf "$exe_path" "$BIN_DIR/$EXE_NAME"
    ok "linked to $BIN_DIR/$EXE_NAME"

    if [ -n "$DESKTOP_DIR" ]; then
        log "setting up desktop shortcut..."
        mkdir -p "$ICON_DIR" "$DESKTOP_DIR"
        
        if [[ "$ICON_INPUT" =~ ^https?:// ]]; then
            curl -sL "$ICON_INPUT" -o "$ICON_DIR/shonenx.png"
        else
            cp -f "${ICON_INPUT/#\~/$HOME}" "$ICON_DIR/shonenx.png" 2>/dev/null || true
        fi

        cat > "$DESKTOP_DIR/shonenx.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=ShonenX
Exec=$BIN_DIR/$EXE_NAME %u
Icon=$ICON_DIR/shonenx.png
Terminal=false
Type=Application
Categories=Network;Entertainment;
EOF
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
    fi

    setup_path
    save_cache
    ok "install complete! run '$EXE_NAME' to start."
}

core_uninstall() {
    $CLI_MODE || clear
    log "removing ShonenX..."
    rm -rf "$INSTALL_DIR" "/tmp/shonenx_install_latest.sh"
    rm -f "$BIN_DIR/$EXE_NAME" "$BIN_DIR/shonenx-manager"

    if [ -n "$DESKTOP_DIR" ]; then
        rm -f "$DESKTOP_DIR/shonenx.desktop" "$ICON_DIR/shonenx.png"
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
    fi

    ok "uninstalled completely."
}

core_status() {
    $CLI_MODE || clear
    echo -e "\033[35m\033[1m--- System Status ---\033[0m\n"
    if [ -f "$BIN_DIR/$EXE_NAME" ]; then
        echo -e "App Status : \033[32mInstalled\033[0m"
        echo -e "Binary     : $BIN_DIR/$EXE_NAME"
    else
        echo -e "App Status : \033[31mNot Installed\033[0m"
    fi
    echo -e "Target Repo: $REPO"
    echo -e "Install Dir: $INSTALL_DIR\n"
}

draw_menu() {
    local sel=$1
    clear
    echo -e "\033[35m\033[1m  +---------------------------------------+"
    echo -e "  |        ShonenX Installer GUI          |"
    echo -e "  +---------------------------------------+\033[0m\n"

    local opts=("Quick Install (Latest)" "Rollback / Select Version" "Custom Setup (Repo/Path)" "System Status" "Uninstall" "Exit")
    
    for i in "${!opts[@]}"; do
        if [ "$i" -eq "$sel" ]; then
            echo -e "    \033[45m\033[37m\033[1m > ${opts[$i]} \033[0m"
        else
            echo -e "       ${opts[$i]}"
        fi
    done
    
    echo -e "\n  \033[90mUse Up/Down arrows to navigate, Enter to select. Press Ctrl+C to exit.\033[0m"
}

run_tui() {
    local selected=0
    local opt_count=6

    tput civis 2>/dev/null || true

    while true; do
        draw_menu $selected
        
        read -rsn1 key || true
        
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 seq || true
            case "$seq" in
                "[A"|"OA") 
                    [ "$selected" -gt 0 ] && ((selected--)) || true 
                    ;;
                "[B"|"OB") 
                    [ "$selected" -lt $((opt_count - 1)) ] && ((selected++)) || true 
                    ;;
            esac
        elif [[ $key == "" ]]; then
            tput cnorm 2>/dev/null || true 
            
            case $selected in
                0) 
                   SELECTED_TAG="latest"
                   core_install 
                   ;;
                1) 
                   fetch_and_select_tag
                   core_install
                   ;;
                2) 
                   clear
                   echo -e "\033[35m--- Custom Setup ---\033[0m\n"
                   read -rp "Repo [$REPO]: " r; [ -n "$r" ] && REPO="$r"
                   read -rp "Install Path [$INSTALL_DIR]: " d; [ -n "$d" ] && INSTALL_DIR="$d"
                   read -rp "Icon URL/Path [$ICON_INPUT]: " i; [ -n "$i" ] && ICON_INPUT="$i"
                   fetch_and_select_tag
                   core_install 
                   ;;
                3) core_status ;;
                4) 
                   clear
                   read -rp "Type YES to confirm uninstall: " confirm
                   [ "$confirm" = "YES" ] && { core_uninstall; rm -rf "$CACHE_DIR"; } || warn "aborted."
                   ;;
                5) clear; echo "Goodbye!"; exit 0 ;;
            esac
            
            echo -e "\n\033[90mPress any key to return to menu...\033[0m"
            read -rsn1 || true
            tput civis 2>/dev/null || true
        fi
    done
}

# parse arguments for power users
while [[ $# -gt 0 ]]; do
    CLI_MODE=true
    case "$1" in
        --install)   ACTION="install" ;;
        --uninstall) ACTION="uninstall" ;;
        --status)    ACTION="status" ;;
        --repo)      REPO="$2"; shift ;;
        --tag)       SELECTED_TAG="$2"; shift ;;
        --dir)       INSTALL_DIR="$2"; shift ;;
        --icon)      ICON_INPUT="$2"; shift ;;
        --clear-cache) 
            rm -rf "$CACHE_DIR"
            ok "installer cache cleared."
            exit 0
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --install           Run installation"
            echo "  --uninstall         Remove application"
            echo "  --status            Check current status"
            echo "  --repo <user/repo>  Specify custom GitHub repository"
            echo "  --tag <tag>         Specify release tag (default: latest)"
            echo "  --dir <path>        Specify custom installation directory"
            echo "  --icon <path|url>   Specify custom icon for desktop entry"
            echo "  --clear-cache       Reset saved custom repo/dir configurations"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *) err "unknown flag: $1. use --help for options."; exit 1 ;;
    esac
    shift
done

if [ "$CLI_MODE" = true ]; then
    [ -z "$ACTION" ] && ACTION="install"
    case "$ACTION" in
        install) core_install ;;
        uninstall) core_uninstall ;;
        status) core_status ;;
    esac
else
    run_tui
fi