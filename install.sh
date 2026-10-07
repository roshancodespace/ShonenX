#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REPO="${SHONENX_REPO:-${REPO:-roshancodespace/ShonenX}}"
EXE_NAME="shonenx"
DEFAULT_ICON_URL="https://raw.githubusercontent.com/roshancodespace/shonenx/main/assets/images/app_icon.png"

# Temporary directory handling with safe cleanup
TMP_DIR=""
cleanup() {
    [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT
trap 'cleanup; echo -e "\n\033[31m[!] Operation aborted.\033[0m"; exit 130' INT TERM

IS_TERMUX=false
IS_IMMUTABLE=false
SUDO="sudo"

if [ -n "${TERMUX_VERSION:-}" ]; then
    IS_TERMUX=true
    SUDO=""
    BIN_DIR="$PREFIX/bin"
    DESKTOP_DIR=""
    ICON_DIR=""
    DEFAULT_INSTALL_DIR="$HOME/.local/share/shonenx"
    CACHE_DIR="$HOME/.config/shonenx"
    DOCS_DIR="$HOME/storage/shared/Documents"
    [ ! -d "$DOCS_DIR" ] && DOCS_DIR="$HOME/Documents"
else
    command -v sudo >/dev/null 2>&1 || SUDO=""
    BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
    DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
    ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/512x512/apps"
    DEFAULT_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/shonenx"
    CACHE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shonenx"
    DOCS_DIR="$(command -v xdg-user-dir >/dev/null 2>&1 && xdg-user-dir DOCUMENTS 2>/dev/null || echo "$HOME/Documents")"
fi

# Detect immutable / atomic OS (Bazzite, Fedora Silverblue/Kinoite/Atomic, SteamOS, vanilla OS, etc.)
if [ -f /run/ostree-booted ] || [ -d /sysroot/ostree ] || [ ! -w /usr ]; then
    IS_IMMUTABLE=true
elif [ -f /etc/os-release ]; then
    if grep -qiE "bazzite|silverblue|kinoite|sericea|onyx|atomic|steamos" /etc/os-release 2>/dev/null; then
        IS_IMMUTABLE=true
    fi
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
PREFER_ZIP=false
PREFER_APPIMAGE=false

if [ -f "$CACHE_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CACHE_FILE" 2>/dev/null || true
fi

log()  { echo -e "\033[36m[*]\033[0m $1"; }
ok()   { echo -e "\033[32m[+]\033[0m $1"; }
err()  { echo -e "\033[31m[!]\033[0m $1"; }
warn() { echo -e "\033[33m[!]\033[0m $1"; }

detect_system_arch() {
    local raw_arch
    raw_arch="$(uname -m 2>/dev/null || echo "unknown")"
    case "$raw_arch" in
        x86_64|amd64)
            SYSTEM_ARCH="x86_64"
            ALT_ARCH="amd64"
            ;;
        aarch64|arm64)
            SYSTEM_ARCH="aarch64"
            ALT_ARCH="arm64"
            ;;
        armv7l|armv7|armhf)
            SYSTEM_ARCH="armv7"
            ALT_ARCH="armhf"
            ;;
        *)
            SYSTEM_ARCH="$raw_arch"
            ALT_ARCH=""
            ;;
    esac
}

save_cache() {
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
    {
        echo "REPO=\"$REPO\""
        echo "ICON_INPUT=\"$ICON_INPUT\""
        echo "INSTALL_DIR=\"$INSTALL_DIR\""
        echo "PREFER_ZIP=\"$PREFER_ZIP\""
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
    # shellcheck disable=SC2086
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
    
    local missing_mpv=0
    local missing_secret=0
    local missing_webkit=0
    local missing_ffmpeg=0

    if ! $IS_TERMUX; then
        ldconfig -p 2>/dev/null | grep -q "libmpv" || missing_mpv=1
        ldconfig -p 2>/dev/null | grep -q "libsecret" || missing_secret=1
        ldconfig -p 2>/dev/null | grep -q -i "webkit2gtk\|webkitgtk" || missing_webkit=1
    else
        command -v mpv >/dev/null 2>&1 || missing_mpv=1
    fi

    command -v ffmpeg >/dev/null 2>&1 || missing_ffmpeg=1

    local total_missing=$((missing_mpv + missing_secret + missing_webkit + missing_ffmpeg))

    if [ "$total_missing" -eq 0 ]; then
        ok "all recommended system dependencies found."
        return 0
    fi

    # On immutable / atomic systems, NEVER attempt to invoke package managers modifying the host OS.
    if [ "$IS_IMMUTABLE" = true ]; then
        log "detected immutable/atomic OS (OSTree/Bazzite/SteamOS/Silverblue)."
        log "skipping host package-manager modifications. System libraries are managed by the OS image."
        if [ "$missing_mpv" -eq 1 ]; then
            warn "Note: libmpv not found in ldconfig. If media playback has issues, ensure mpv is in your base image."
        fi
        if [ "$missing_ffmpeg" -eq 1 ]; then
            warn "Note: ffmpeg not found. ShonenX will use raw segment stitching for TS downloads."
        fi
        return 0
    fi

    # Non-interactive environment without sudo credentials: skip
    if ! $IS_TERMUX && [ ! -t 0 ]; then
        if [ -n "$SUDO" ] && ! sudo -n true 2>/dev/null; then
            log "non-interactive environment: skipping sudo dependency checks."
            return 0
        fi
    fi

    warn "missing some recommended dependencies (mpv/libsecret/webkit/ffmpeg)."
    if [ "$missing_ffmpeg" -eq 1 ]; then
        log "Note: ShonenX defaults to FFmpeg for safely remuxing downloaded TS segments."
        log "If skipped, it will fallback to a raw, unsafe stitching method."
    fi
    
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
    tput civis 2>/dev/null || true 

    if [ "$failed" -eq 1 ]; then
        warn "Package manager installation was skipped or encountered an issue."
        warn "Continuing user-space installation. ShonenX may still run fine."
        sleep 1
    else
        ok "dependencies installed."
    fi
    
    return 0
}

setup_path() {
    $IS_TERMUX && return 0
    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        ok "$BIN_DIR is already in your PATH."
        return 0
    fi

    warn "$BIN_DIR is NOT currently in your PATH."
    log "adding $BIN_DIR to shell configuration files..."

    local added=false
    if [ -f "$HOME/.bashrc" ] && ! grep -qF "$BIN_DIR" "$HOME/.bashrc"; then
        echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc" && added=true || true
    fi
    if [ -f "$HOME/.zshrc" ] && ! grep -qF "$BIN_DIR" "$HOME/.zshrc"; then
        echo -e "\nexport PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.zshrc" && added=true || true
    fi
    if [ -d "$HOME/.config/fish" ]; then
        touch "$HOME/.config/fish/config.fish" 2>/dev/null || true
        if ! grep -qF "$BIN_DIR" "$HOME/.config/fish/config.fish"; then
            echo -e "\nfish_add_path $BIN_DIR" >> "$HOME/.config/fish/config.fish" && added=true || true
        fi
    fi

    echo ""
    log "To run '$EXE_NAME' from your current terminal immediately, run:"
    echo -e "    \033[32mexport PATH=\"\$PATH:$BIN_DIR\"\033[0m"
    if [ "$added" = true ]; then
        log "Or restart your terminal session for PATH changes to take effect."
    fi
    echo ""
    return 0
}

find_release_assets() {
    local json="$1"
    APPIMAGE_URL=""
    ZIP_URL=""

    local all_urls
    all_urls=$(echo "$json" | grep -o '"browser_download_url": "[^"]*' | sed 's/"browser_download_url": "//' || true)

    # 1. Search for AppImage matching arch
    while read -r url; do
        [ -z "$url" ] && continue
        local fname="${url##*/}"
        if [[ "$fname" =~ \.[Aa][Pp][Pp][Ii][Mm][Aa][Gg][Ee]$ ]]; then
            if [[ "$fname" == *"$SYSTEM_ARCH"* ]] || ([ -n "$ALT_ARCH" ] && [[ "$fname" == *"$ALT_ARCH"* ]]); then
                APPIMAGE_URL="$url"
                break
            elif [[ "$SYSTEM_ARCH" == "x86_64" ]] && [[ "$fname" =~ [Ll]inux.*\.AppImage$ ]] && ! [[ "$fname" =~ (arm|aarch|x86_32|i686) ]]; then
                APPIMAGE_URL="$url"
                break
            fi
        fi
    done <<< "$all_urls"

    # 2. Search for Linux ZIP matching arch
    while read -r url; do
        [ -z "$url" ] && continue
        local fname="${url##*/}"
        if [[ "$fname" =~ \.[Zz][Ii][Pp]$ ]] && [[ "$fname" =~ [Ll]inux|[Ll]INUX ]]; then
            if [[ "$fname" == *"$SYSTEM_ARCH"* ]] || ([ -n "$ALT_ARCH" ] && [[ "$fname" == *"$ALT_ARCH"* ]]); then
                ZIP_URL="$url"
                break
            elif [[ "$SYSTEM_ARCH" == "x86_64" ]] && ! [[ "$fname" =~ (arm|aarch|x86_32|i686) ]]; then
                ZIP_URL="$url"
                break
            fi
        fi
    done <<< "$all_urls"
}

check_fuse_capability() {
    local appimage="$1"

    # Attempt to query the AppImage version / help
    local output
    output=$("$appimage" --appimage-version 2>&1 || true)
    
    if echo "$output" | grep -qiE "libfuse\.so\.2|require FUSE|cannot mount"; then
        return 1
    fi

    # Also test /dev/fuse accessibility if present
    if [ ! -e /dev/fuse ]; then
        return 1
    fi

    return 0
}

core_install() {
    $CLI_MODE || clear
    detect_system_arch

    case "$SYSTEM_ARCH" in
        x86_64|aarch64) ;;
        *)
            err "unsupported architecture: $SYSTEM_ARCH. ShonenX Linux builds support x86_64 and aarch64."
            return 1
            ;;
    esac

    check_dependencies

    log "fetching release info for $REPO ($SYSTEM_ARCH)..."
    local release_json=""
    if [ "$SELECTED_TAG" != "latest" ]; then
        release_json=$(curl -sL "https://api.github.com/repos/$REPO/releases/tags/$SELECTED_TAG")
    else
        release_json=$(curl -sL "https://api.github.com/repos/$REPO/releases/latest")
        if echo "$release_json" | grep -q '"message": "Not Found"'; then
            local fallback_json
            fallback_json=$(curl -sL "https://api.github.com/repos/$REPO/releases?per_page=1")
            if echo "$fallback_json" | grep -q '"tag_name":'; then
                release_json="$fallback_json"
            fi
        fi
    fi

    if echo "$release_json" | grep -q '"message": "Not Found"'; then
        err "repo or release not found: $REPO ($SELECTED_TAG)"
        return 1
    fi

    local version
    version=$(echo "$release_json" | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//' | head -n 1)

    find_release_assets "$release_json"

    if [ -z "$APPIMAGE_URL" ] && [ -z "$ZIP_URL" ]; then
        err "no compatible Linux artifact found for architecture '$SYSTEM_ARCH' in release $version."
        return 1
    fi

    # Determine candidate format
    local chosen_format=""
    if [ "$PREFER_ZIP" = true ] && [ -n "$ZIP_URL" ]; then
        chosen_format="zip"
    elif [ "$PREFER_APPIMAGE" = true ] && [ -n "$APPIMAGE_URL" ]; then
        chosen_format="appimage"
    elif [ -n "$APPIMAGE_URL" ]; then
        chosen_format="appimage"
    else
        chosen_format="zip"
    fi

    # Create safe temporary staging directory
    TMP_DIR="$(mktemp -d -t shonenx-install.XXXXXX 2>/dev/null || mktemp -d)"

    local installed_target_bin=""
    local install_success=false

    # Attempt AppImage flow
    if [ "$chosen_format" = "appimage" ]; then
        log "downloading AppImage ($version, $SYSTEM_ARCH)..."
        local tmp_appimage="$TMP_DIR/shonenx.AppImage"
        if ! curl -# -L "$APPIMAGE_URL" -o "$tmp_appimage"; then
            err "failed to download AppImage."
            return 1
        fi

        if [ ! -s "$tmp_appimage" ]; then
            err "downloaded AppImage is empty."
            return 1
        fi

        chmod +x "$tmp_appimage"

        log "verifying AppImage runtime & FUSE compatibility..."
        if ! check_fuse_capability "$tmp_appimage"; then
            warn "AppImage execution failed: FUSE (libfuse.so.2) is not available on this system."
            
            if [ -n "$ZIP_URL" ]; then
                log "automatically falling back to standalone Linux ZIP archive..."
                chosen_format="zip"
            else
                log "no Linux ZIP release found; attempting FUSE-less AppImage extraction..."
                local extract_dir="$TMP_DIR/extracted"
                mkdir -p "$extract_dir"
                if (cd "$extract_dir" && "$tmp_appimage" --appimage-extract >/dev/null 2>&1); then
                    ok "extracted AppImage contents successfully without FUSE."
                    local extracted_root="$extract_dir/squashfs-root"
                    mkdir -p "$INSTALL_DIR"
                    rm -rf "$INSTALL_DIR"/*
                    cp -r "$extracted_root"/* "$INSTALL_DIR"/
                    local found_bin
                    found_bin=$(find "$INSTALL_DIR" -maxdepth 2 -type f \( -name "$EXE_NAME" -o -name "ShonenX" -o -name "AppRun" \) -executable 2>/dev/null | head -n 1)
                    [ -z "$found_bin" ] && found_bin="$INSTALL_DIR/AppRun"
                    chmod +x "$found_bin"
                    installed_target_bin="$found_bin"
                    install_success=true
                else
                    err "AppImage requires FUSE (libfuse.so.2) to run."
                    err "Please install fuse2/libfuse2 on your host, or install using a standalone ZIP archive."
                    return 1
                fi
            fi
        else
            mkdir -p "$INSTALL_DIR"
            # Remove any prior bundle files while preserving directory
            rm -rf "$INSTALL_DIR"/*
            cp -f "$tmp_appimage" "$INSTALL_DIR/$EXE_NAME.AppImage"
            chmod +x "$INSTALL_DIR/$EXE_NAME.AppImage"
            installed_target_bin="$INSTALL_DIR/$EXE_NAME.AppImage"
            install_success=true
            ok "AppImage installed to $INSTALL_DIR/$EXE_NAME.AppImage"
        fi
    fi

    # Fallback or primary ZIP flow
    if [ "$chosen_format" = "zip" ] && [ "$install_success" = false ]; then
        if [ -z "$ZIP_URL" ]; then
            err "no Linux ZIP archive available for $SYSTEM_ARCH."
            return 1
        fi

        log "downloading standalone Linux bundle ($version, $SYSTEM_ARCH)..."
        local tmp_zip="$TMP_DIR/shonenx.zip"
        if ! curl -# -L "$ZIP_URL" -o "$tmp_zip"; then
            err "failed to download Linux ZIP archive."
            return 1
        fi

        if [ ! -s "$tmp_zip" ]; then
            err "downloaded ZIP is empty."
            return 1
        fi

        log "verifying ZIP archive integrity..."
        if ! unzip -tq "$tmp_zip" >/dev/null 2>&1; then
            err "downloaded archive is corrupt or incomplete."
            return 1
        fi

        local extract_dir="$TMP_DIR/extracted"
        mkdir -p "$extract_dir"
        unzip -q -o "$tmp_zip" -d "$extract_dir"

        local exe_candidate
        exe_candidate=$(find "$extract_dir" -maxdepth 3 -type f \( -name "$EXE_NAME" -o -name "ShonenX" \) -executable 2>/dev/null | head -n 1)
        if [ -z "$exe_candidate" ]; then
            exe_candidate=$(find "$extract_dir" -maxdepth 3 -type f \( -name "$EXE_NAME" -o -name "ShonenX" \) 2>/dev/null | head -n 1)
        fi

        if [ -z "$exe_candidate" ]; then
            err "could not locate '$EXE_NAME' binary inside extracted archive."
            return 1
        fi

        local bundle_root
        bundle_root="$(dirname "$exe_candidate")"

        mkdir -p "$INSTALL_DIR"
        rm -rf "$INSTALL_DIR"/*
        cp -r "$bundle_root"/* "$INSTALL_DIR"/

        local target_bin="$INSTALL_DIR/$(basename "$exe_candidate")"
        chmod +x "$target_bin"
        installed_target_bin="$target_bin"
        install_success=true
        ok "standalone bundle installed to $INSTALL_DIR"
    fi

    if [ "$install_success" = false ] || [ -z "$installed_target_bin" ]; then
        err "installation failed to produce an executable binary."
        return 1
    fi

    # Create launcher script in ~/.local/bin
    mkdir -p "$BIN_DIR"
    cat > "$BIN_DIR/$EXE_NAME" <<EOF
#!/usr/bin/env bash
# ShonenX launcher
# Workaround for WebKitGTK DMA-BUF issue with NVIDIA/Wayland
export WEBKIT_DISABLE_DMABUF_RENDERER="\${WEBKIT_DISABLE_DMABUF_RENDERER:-1}"
exec "$installed_target_bin" "\$@"
EOF
    chmod +x "$BIN_DIR/$EXE_NAME"
    ok "configured launcher at $BIN_DIR/$EXE_NAME"

    # Desktop shortcut & icon integration
    if [ -n "$DESKTOP_DIR" ]; then
        log "setting up desktop launcher and icon..."
        mkdir -p "$ICON_DIR" "$DESKTOP_DIR"

        # Attempt to locate icon from the installed files first
        local local_icon
        local_icon=$(find "$INSTALL_DIR" -type f \( -name "shonenx.png" -o -name "app_icon.png" -o -name "application_icon.png" \) 2>/dev/null | head -n 1)

        if [ -n "$local_icon" ] && [ -f "$local_icon" ]; then
            cp -f "$local_icon" "$ICON_DIR/shonenx.png"
        elif [[ "$ICON_INPUT" =~ ^https?:// ]]; then
            curl -sL "$ICON_INPUT" -o "$ICON_DIR/shonenx.png" 2>/dev/null || true
        else
            cp -f "${ICON_INPUT/#\~/$HOME}" "$ICON_DIR/shonenx.png" 2>/dev/null || true
        fi

        cat > "$DESKTOP_DIR/shonenx.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=ShonenX
Comment=Minimal yet feature-rich Anime/Manga Client
Exec="$BIN_DIR/$EXE_NAME" %u
Icon=$ICON_DIR/shonenx.png
Terminal=false
Type=Application
Categories=Network;AudioVideo;Player;Entertainment;
MimeType=x-scheme-handler/aniyomi;x-scheme-handler/tachiyomi;x-scheme-handler/mangayomi;x-scheme-handler/cloudstream;x-scheme-handler/cloudstreamrepo;x-scheme-handler/kotatsu;x-scheme-handler/sora;x-scheme-handler/shonenx;x-scheme-handler/mihon;
StartupWMClass=shonenx
EOF
        chmod 644 "$DESKTOP_DIR/shonenx.desktop"

        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
        fi

        if command -v xdg-mime >/dev/null 2>&1; then
            for scheme in aniyomi tachiyomi mangayomi cloudstream cloudstreamrepo kotatsu sora shonenx mihon; do
                xdg-mime default shonenx.desktop "x-scheme-handler/$scheme" 2>/dev/null || true
            done
        fi
        ok "created desktop entry at $DESKTOP_DIR/shonenx.desktop"
    fi

    setup_path
    save_cache
    ok "installation complete! run '$EXE_NAME' to start ShonenX."
}

core_uninstall() {
    $CLI_MODE || clear
    
    if [ "$DRY_RUN" = true ]; then
        warn "=== DRY RUN MODE: No files will be deleted ==="
    fi

    log "stopping any running ShonenX processes..."
    if pgrep -x "$EXE_NAME" >/dev/null 2>&1; then
        if [ "$DRY_RUN" = true ]; then
            log "[dry-run] would terminate running ShonenX processes"
        else
            pkill -x "$EXE_NAME" 2>/dev/null || true
            sleep 1
            ok "terminated running ShonenX processes."
        fi
    fi

    log "uninstall mode: $UNINSTALL_MODE"
    log "removing ShonenX binaries and shortcuts..."

    remove_path "$INSTALL_DIR" "installation directory"
    remove_path "${XDG_DATA_HOME:-$HOME/.local/share}/ShonenX" "legacy installation directory"
    remove_path "$BIN_DIR/$EXE_NAME" "binary launcher"
    remove_path "$BIN_DIR/shonenx-manager" "manager symlink"
    remove_path "$HOME/.local/bin/$EXE_NAME" "local binary launcher"
    remove_path "$HOME/.local/bin/shonenx-manager" "local manager symlink"

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

    remove_path "/tmp/shonenx.zip" "temporary download zip"
    remove_path "/tmp/shonenx_install_latest.sh" "temporary installer script"
    remove_glob "/tmp/shonenx*" "temporary runtime files"

    if [ "$UNINSTALL_MODE" = "keep-data" ]; then
        ok "uninstalled ShonenX binaries and shortcuts. user data preserved."
        return 0
    fi

    log "cleaning user caches and configs..."
    remove_path "$CACHE_DIR" "installer cache & configs"
    remove_path "${XDG_CONFIG_HOME:-$HOME/.config}/ShonenX" "config directory"
    remove_path "${XDG_CONFIG_HOME:-$HOME/.config}/shonenx" "lowercase config directory"
    remove_path "${XDG_CONFIG_HOME:-$HOME/.config}/com.roshancodespace.shonenx" "app config directory"

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
    detect_system_arch
    echo -e "\033[35m\033[1m--- System Status ---\033[0m\n"
    if [ -f "$BIN_DIR/$EXE_NAME" ] || [ -d "$INSTALL_DIR" ]; then
        echo -e "App Status   : \033[32mInstalled\033[0m"
        [ -f "$BIN_DIR/$EXE_NAME" ] && echo -e "Launcher     : $BIN_DIR/$EXE_NAME"
    else
        echo -e "App Status   : \033[31mNot Installed\033[0m"
    fi
    echo -e "Architecture : $SYSTEM_ARCH"
    echo -e "System Type  : $([ "$IS_IMMUTABLE" = true ] && echo -e "\033[33mImmutable / Atomic OS (OSTree/Bazzite/Silverblue)\033[0m" || echo "Traditional Linux")"
    echo -e "Target Repo  : $REPO"
    echo -e "Install Dir  : $INSTALL_DIR"
    echo -e "Bin Dir      : $BIN_DIR $([[ ":$PATH:" == *":$BIN_DIR:"* ]] && echo -e "\033[32m(in PATH)\033[0m" || echo -e "\033[33m(NOT in PATH)\033[0m")"
    echo -e "Desktop Dir  : $DESKTOP_DIR $([ -f "$DESKTOP_DIR/shonenx.desktop" ] && echo -e "\033[32m(desktop entry exists)\033[0m" || echo -e "\033[90m(none)\033[0m")"
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
        draw_menu "$selected"
        
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
                5) clear; exit 0 ;;
            esac
            
            echo -e "\n\033[90mPress any key to return to menu...\033[0m"
            read -rsn1 || true
            tput civis 2>/dev/null || true
        fi
    done
}

while [[ $# -gt 0 ]]; do
    CLI_MODE=true
    case "$1" in
        --install)          ACTION="install" ;;
        --skip-deps|--no-deps) SKIP_DEPS=true ;;
        --prefer-zip)       PREFER_ZIP=true ;;
        --prefer-appimage)  PREFER_APPIMAGE=true ;;
        --uninstall)        ACTION="uninstall" ;;
        --purge)            ACTION="uninstall"; UNINSTALL_MODE="purge" ;;
        --keep-downloads)   UNINSTALL_MODE="keep-downloads" ;;
        --keep-data)        UNINSTALL_MODE="keep-data" ;;
        --dry-run)          DRY_RUN=true ;;
        --status)           ACTION="status" ;;
        -r|--repo)          REPO="$2"; shift ;;
        --repo=*)           REPO="${1#*=}" ;;
        -t|--tag)           SELECTED_TAG="$2"; shift ;;
        --tag=*)            SELECTED_TAG="${1#*=}" ;;
        -d|--dir)           INSTALL_DIR="$2"; shift ;;
        --dir=*)            INSTALL_DIR="${1#*=}" ;;
        -i|--icon)          ICON_INPUT="$2"; shift ;;
        --icon=*)           ICON_INPUT="${1#*=}" ;;
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
            echo "  --prefer-zip        Prefer standalone Linux ZIP package over AppImage"
            echo "  --prefer-appimage   Prefer AppImage package over ZIP package"
            echo "  --skip-deps         Skip dependency checking and installation"
            echo "  --repo <user/repo>  Specify custom GitHub repository (default: $DEFAULT_REPO)"
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