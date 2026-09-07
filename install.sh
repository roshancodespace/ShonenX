#!/usr/bin/env bash
set -euo pipefail

# always restore cursor and exit cleanly if user hits Ctrl+C
trap 'tput cnorm 2>/dev/null || true; echo -e "\n\033[31m[!] Operation aborted.\033[0m"; exit 130' INT TERM

# defaults
DEFAULT_REPO="roshancodespace/ShonenX"
EXE_NAME="shonenx"
DEFAULT_ICON_URL="https://raw.githubusercontent.com/roshancodespace/shonenx/main/assets/images/app_icon.png"

# figure out paths depending on if we are on termux or normal linux
IS_TERMUX=false
SUDO="sudo"
if [ -n "${TERMUX_VERSION:-}" ]; then
    IS_TERMUX=true; SUDO=""
    BIN_DIR="$PREFIX/bin"
    DESKTOP_DIR=""
    ICON_DIR=""
    DEFAULT_INSTALL_DIR="$HOME/.local/share/ShonenX"
    CACHE_DIR="$HOME/.config/ShonenX"
    DOCS_DIR="$HOME/storage/shared/Documents"
    [ ! -d "$DOCS_DIR" ] && DOCS_DIR="$HOME/Documents"
else
    command -v sudo >/dev/null 2>&1 || SUDO=""
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/512x512/apps"
    DEFAULT_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ShonenX"
    CACHE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ShonenX"
    DOCS_DIR="$(command -v xdg-user-dir >/dev/null 2>&1 && xdg-user-dir DOCUMENTS 2>/dev/null || echo "$HOME/Documents")"
fi

CACHE_FILE="$CACHE_DIR/installer.cache"
REPO="$DEFAULT_REPO"
ICON_INPUT="$DEFAULT_ICON_URL"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
SELECTED_TAG="latest"
CLI_MODE=false
ACTION=""
DRY_RUN=false
UNINSTALL_MODE="purge"
SKIP_DEPS=false

# load previous settings if they exist
if [ -f "$CACHE_FILE" ]; then
    source "$CACHE_FILE" 2>/dev/null || true
fi

# print helpers
log()  { echo -e "\033[36m[*]\033[0m $1"; }
ok()   { echo -e "\033[32m[+]\033[0m $1"; }
err()  { echo -e "\033[31m[!]\033[0m $1"; }
warn() { echo -e "\033[33m[!]\033[0m $1"; }

save_cache() {
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
    {
        echo "REPO=\"$REPO\""
        echo "ICON_INPUT=\"$ICON_INPUT\""
        echo "INSTALL_DIR=\"$INSTALL_DIR\""
    } > "$CACHE_FILE" 2>/dev/null || true
    return 0
}

declare -A PROCESSED_PATHS=()

remove_path() {
    local target="$1"
    local desc="${2:-}"
    [ -z "$target" ] && return 0
    [ -n "${PROCESSED_PATHS["$target"]:-}" ] && return 0
    PROCESSED_PATHS["$target"]=1

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$DRY_RUN" = true ]; then
            log "[dry-run] would remove: $target ${desc:+($desc)}"
        else
            rm -rf "$target"
            ok "removed: $target ${desc:+($desc)}"
        fi
    fi
}

remove_glob() {
    local pattern="$1"
    local desc="${2:-}"
    for item in $pattern; do
        if [ -e "$item" ] || [ -L "$item" ]; then
            if [ "$DRY_RUN" = true ]; then
                log "[dry-run] would remove: $item ${desc:+($desc)}"
            else
                rm -rf "$item"
                ok "removed: $item ${desc:+($desc)}"
            fi
        fi
    done
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
    if [ "$SKIP_DEPS" = true ]; then
        return 0
    fi

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

    # Non-interactive shell (in-app updater): skip sudo password prompt to avoid hanging/failing
    if ! $IS_TERMUX && [ ! -t 0 ]; then
        if [ -n "$SUDO" ] && ! sudo -n true 2>/dev/null; then
            log "non-interactive environment: skipping sudo dependency checks."
            return 0
        fi
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
    $IS_TERMUX && return 0
    [[ ":$PATH:" == *":$BIN_DIR:"* ]] && return 0

    log "adding $BIN_DIR to PATH in shell configs..."
    if [ -f "$HOME/.bashrc" ] && ! grep -qF "$BIN_DIR" "$HOME/.bashrc"; then
        echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc" || true
    fi
    if [ -f "$HOME/.zshrc" ] && ! grep -qF "$BIN_DIR" "$HOME/.zshrc"; then
        echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc" || true
    fi
    
    if [ -d "$HOME/.config/fish" ]; then
        touch "$HOME/.config/fish/config.fish" 2>/dev/null || true
        if ! grep -qF "$BIN_DIR" "$HOME/.config/fish/config.fish"; then
            echo -e "\nfish_add_path $BIN_DIR" >> "$HOME/.config/fish/config.fish" || true
        fi
    fi
    return 0
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

    if [ -d "$INSTALL_DIR/linux" ]; then
        find "$INSTALL_DIR/linux" -maxdepth 1 -mindepth 1 -exec mv -t "$INSTALL_DIR" {} + 2>/dev/null || true
        rmdir "$INSTALL_DIR/linux" 2>/dev/null || true
    fi

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
    
    if [ "$DRY_RUN" = true ]; then
        warn "=== DRY RUN MODE: No files will be deleted ==="
    fi

    log "stopping any running ShonenX processes..."
    if pgrep -f "(^|/)$EXE_NAME" >/dev/null 2>&1; then
        if [ "$DRY_RUN" = true ]; then
            log "[dry-run] would terminate running ShonenX processes"
        else
            pkill -f "(^|/)$EXE_NAME" 2>/dev/null || true
            sleep 1
            ok "terminated running ShonenX processes."
        fi
    fi

    log "uninstall mode: $UNINSTALL_MODE"
    log "removing ShonenX binaries and shortcuts..."

    # 1. Binaries & installation folder
    remove_path "$INSTALL_DIR" "installation directory"
    remove_path "$BIN_DIR/$EXE_NAME" "binary symlink"
    remove_path "$BIN_DIR/shonenx-manager" "manager symlink"
    remove_path "$HOME/.local/bin/$EXE_NAME" "local binary symlink"
    remove_path "$HOME/.local/bin/shonenx-manager" "local manager symlink"

    # 2. Desktop entries & icons
    if [ -n "$DESKTOP_DIR" ]; then
        remove_path "$DESKTOP_DIR/shonenx.desktop" "desktop launcher"
        remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/applications/shonenx.desktop" "desktop launcher"
        remove_path "$ICON_DIR/shonenx.png" "application icon"
        remove_glob "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/*/apps/shonenx.png" "icon theme"
        remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/pixmaps/shonenx.png" "pixmap icon"
        if [ "$DRY_RUN" = false ]; then
            command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
            command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" 2>/dev/null || true
        fi
    fi

    # 3. Temp files
    remove_path "/tmp/shonenx.zip" "temporary download zip"
    remove_path "/tmp/shonenx_install_latest.sh" "temporary installer script"
    remove_glob "/tmp/shonenx*" "temporary runtime files"

    # If keep-data was requested, exit early
    if [ "$UNINSTALL_MODE" = "keep-data" ]; then
        ok "uninstalled ShonenX binaries and shortcuts. user data preserved."
        return 0
    fi

    log "cleaning user caches and configs..."
    # 4. Installer cache & configs
    remove_path "$CACHE_DIR" "installer cache & configs"
    remove_path "${XDG_CONFIG_HOME:-$HOME/.config}/ShonenX" "config directory"
    remove_path "${XDG_CONFIG_HOME:-$HOME/.config}/shonenx" "lowercase config directory"
    remove_path "${XDG_CONFIG_HOME:-$HOME/.config}/com.roshancodespace.shonenx" "app config directory"

    # 5. User cache directories (~/.cache)
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/com.roshancodespace.shonenx" "WebKit and app cache"
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/com.shonenx.anime" "legacy app cache"
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/com.example.shonenx" "legacy app cache"
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/ShonenX" "cache directory"
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/shonenx" "lowercase cache directory"
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/flutter_inappwebview/com.roshancodespace.shonenx" "webview cache"
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/flutter_inappwebview/com.shonenx.anime" "legacy webview cache"
    remove_path "${XDG_CACHE_HOME:-$HOME/.cache}/flutter_inappwebview/com.example.shonenx" "legacy webview cache"
    if [ "$DRY_RUN" = false ]; then
        rmdir "${XDG_CACHE_HOME:-$HOME/.cache}/flutter_inappwebview" 2>/dev/null || true
    fi

    # 6. Local share data (~/.local/share)
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/com.roshancodespace.shonenx" "application data & storage"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/com.shonenx.anime" "legacy application data"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/com.example.shonenx" "legacy application data"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/ShonenX" "share directory"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/shonenx" "lowercase share directory"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/flutter_inappwebview/com.roshancodespace.shonenx" "webview data"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/flutter_inappwebview/com.shonenx.anime" "legacy webview data"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/flutter_inappwebview/com.example.shonenx" "legacy webview data"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/flutter_inappwebview/ShonenX" "webview data"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/flutter_inappwebview/shonenx" "webview data"
    if [ "$DRY_RUN" = false ]; then
        rmdir "${XDG_DATA_HOME:-$HOME/.local/share}/flutter_inappwebview" 2>/dev/null || true
    fi

    # 7. User Documents Directory (Documents/ShonenX)
    local target_docs="$DOCS_DIR/ShonenX"
    if [ -d "$target_docs" ]; then
        if [ "$UNINSTALL_MODE" = "keep-downloads" ]; then
            log "cleaning $target_docs while preserving Downloads/..."
            remove_path "$target_docs/databases" "Isar databases"
            remove_path "$target_docs/Theme" "theme & wallpaper data"
            remove_path "$target_docs/app_logs.txt" "application logs"
            remove_path "$target_docs/dsl_providers" "DSL providers"
            remove_path "$target_docs/Extensions" "downloaded extensions"
            remove_path "$target_docs/Runtime" "runtime bridge data"
            ok "preserved downloaded files in $target_docs/Downloads"
        else
            remove_path "$target_docs" "user documents (databases, theme, logs, extensions, downloads)"
        fi
    fi

    if [ "$DRY_RUN" = true ]; then
        ok "dry-run complete. no files were modified."
    else
        ok "ShonenX uninstalled completely! All residual data wiped."
    fi
}

core_status() {
    $CLI_MODE || clear
    echo -e "\033[35m\033[1m--- System Status ---\033[0m\n"
    if [ -f "$BIN_DIR/$EXE_NAME" ] || [ -d "$INSTALL_DIR" ]; then
        echo -e "App Status   : \033[32mInstalled\033[0m"
        [ -f "$BIN_DIR/$EXE_NAME" ] && echo -e "Binary       : $BIN_DIR/$EXE_NAME"
    else
        echo -e "App Status   : \033[31mNot Installed\033[0m"
    fi
    echo -e "Target Repo  : $REPO"
    echo -e "Install Dir  : $INSTALL_DIR"
    echo -e "Config Dir   : $CACHE_DIR $([ -d "$CACHE_DIR" ] && echo -e "\033[32m(exists)\033[0m" || echo -e "\033[90m(none)\033[0m")"
    echo -e "Docs Dir     : $DOCS_DIR/ShonenX $([ -d "$DOCS_DIR/ShonenX" ] && echo -e "\033[32m(exists)\033[0m" || echo -e "\033[90m(none)\033[0m")"
    echo -e "Cache Dir    : ${XDG_CACHE_HOME:-$HOME/.cache}/com.roshancodespace.shonenx $([ -d "${XDG_CACHE_HOME:-$HOME/.cache}/com.roshancodespace.shonenx" ] && echo -e "\033[32m(exists)\033[0m" || echo -e "\033[90m(none)\033[0m")\n"
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
                   echo -e "\033[35m\033[1m--- Uninstall ShonenX ---\033[0m\n"
                   echo "Choose uninstallation mode:"
                   echo "  [1] Complete Purge (wipes app, databases, configs, caches, & all Documents/ShonenX)"
                   echo "  [2] Clean Uninstall (wipes app, databases, configs, caches, but KEEPS Downloads)"
                   echo "  [3] App Only (removes binary and shortcut only, keeps all user data)"
                   echo "  [0] Cancel"
                   echo ""
                   read -rp "Select an option [0]: " u_mode
                   case "$u_mode" in
                       1)
                           read -rp "Type YES to confirm COMPLETE PURGE: " confirm
                           if [ "$confirm" = "YES" ]; then
                               UNINSTALL_MODE="purge"
                               core_uninstall
                           else
                               warn "uninstall aborted."
                           fi
                           ;;
                       2)
                           read -rp "Type YES to confirm uninstall (keeping downloads): " confirm
                           if [ "$confirm" = "YES" ]; then
                               UNINSTALL_MODE="keep-downloads"
                               core_uninstall
                           else
                               warn "uninstall aborted."
                           fi
                           ;;
                       3)
                           read -rp "Type YES to confirm removing application only: " confirm
                           if [ "$confirm" = "YES" ]; then
                               UNINSTALL_MODE="keep-data"
                               core_uninstall
                           else
                               warn "uninstall aborted."
                           fi
                           ;;
                       *)
                           log "uninstall cancelled."
                           ;;
                   esac
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
        --install)          ACTION="install" ;;
        --skip-deps|--no-deps) SKIP_DEPS=true ;;
        --uninstall)        ACTION="uninstall" ;;
        --purge)            ACTION="uninstall"; UNINSTALL_MODE="purge" ;;
        --keep-downloads)   UNINSTALL_MODE="keep-downloads" ;;
        --keep-data)        UNINSTALL_MODE="keep-data" ;;
        --dry-run)          DRY_RUN=true ;;
        --status)           ACTION="status" ;;
        --repo)             REPO="$2"; shift ;;
        --tag)              SELECTED_TAG="$2"; shift ;;
        --dir)              INSTALL_DIR="$2"; shift ;;
        --icon)             ICON_INPUT="$2"; shift ;;
        --clear-cache) 
            rm -rf "$CACHE_DIR"
            ok "installer cache cleared."
            exit 0
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Install Options:"
            echo "  --install           Run installation (default)"
            echo "  --skip-deps         Skip dependency checking and installation"
            echo "  --repo <user/repo>  Specify custom GitHub repository"
            echo "  --tag <tag>         Specify release tag (default: latest)"
            echo "  --dir <path>        Specify custom installation directory"
            echo "  --icon <path|url>   Specify custom icon for desktop entry"
            echo ""
            echo "Uninstall & Cleanup Options:"
            echo "  --uninstall         Remove application, residual data, caches, and Documents/ShonenX"
            echo "  --purge             Full wipe of everything including downloads (default for uninstall)"
            echo "  --keep-downloads    Wipe application, databases, and caches, but keep downloaded media"
            echo "  --keep-data         Remove application binary and desktop entry only (preserve user data)"
            echo "  --dry-run           Preview files and directories that would be removed without deleting"
            echo "  --clear-cache       Reset saved custom repo/dir configurations"
            echo ""
            echo "General:"
            echo "  --status            Check current installation and data directories status"
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