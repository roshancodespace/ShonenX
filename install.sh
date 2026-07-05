#!/usr/bin/env bash
# +----------------------------------------------------------+
# |              ShonenX -- Interactive Installer             |
# |         Ultimate Anime & Manga Client for Linux          |
# +----------------------------------------------------------+

set -euo pipefail

# --- Config ------------------------------------------------
DEFAULT_REPO="roshancodespace/ShonenX"
EXE_NAME="shonenx"
DEFAULT_ICON_URL="https://raw.githubusercontent.com/roshancodespace/shonenx/main/assets/images/app_icon.png"
INSTALL_DIR="$HOME/.local/share/ShonenX"
CACHE_DIR="$HOME/.config/ShonenX"
CACHE_FILE="$CACHE_DIR/installer.cache"
REPO="$DEFAULT_REPO"
ICON_INPUT="$DEFAULT_ICON_URL"

load_cache() {
    if [ -f "$CACHE_FILE" ]; then
        source "$CACHE_FILE" 2>/dev/null || true
    fi
}

save_cache() {
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
    cat > "$CACHE_FILE" <<EOF
REPO="$REPO"
ICON_INPUT="$ICON_INPUT"
EOF
}

load_cache

IS_TERMUX=false
SUDO="sudo"
if [ -n "${TERMUX_VERSION:-}" ]; then
    IS_TERMUX=true; SUDO=""
    BIN_DIR="$PREFIX/bin"; DESKTOP_DIR=""; ICON_DIR=""
else
    command -v sudo >/dev/null 2>&1 || SUDO=""
    BIN_DIR="$HOME/.local/bin"
    DESKTOP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
fi

# --- Colors & Styles ---------------------------------------
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; then
    HAS_COLOR=true
else
    HAS_COLOR=false
fi

if $HAS_COLOR; then
    # Foreground
    C_BLACK=$'\033[30m';    C_RED=$'\033[31m';      C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m';   C_BLUE=$'\033[34m';     C_MAGENTA=$'\033[35m'
    C_CYAN=$'\033[36m';     C_WHITE=$'\033[37m';    C_BRIGHT_BLACK=$'\033[90m'
    C_BRIGHT_RED=$'\033[91m'; C_BRIGHT_GREEN=$'\033[92m'; C_BRIGHT_YELLOW=$'\033[93m'
    C_BRIGHT_BLUE=$'\033[94m'; C_BRIGHT_MAGENTA=$'\033[95m'; C_BRIGHT_CYAN=$'\033[96m'
    C_BRIGHT_WHITE=$'\033[97m'
    # Background
    B_BLACK=$'\033[40m';    B_MAGENTA=$'\033[45m';  B_CYAN=$'\033[46m'
    B_WHITE=$'\033[47m';    B_BRIGHT_BLACK=$'\033[100m'; B_BRIGHT_BLUE=$'\033[104m'
    B_BRIGHT_MAGENTA=$'\033[105m'; B_BRIGHT_CYAN=$'\033[106m'
    # Styles
    S_BOLD=$'\033[1m';      S_DIM=$'\033[2m';       S_ITALIC=$'\033[3m'
    S_UNDERLINE=$'\033[4m'; S_BLINK=$'\033[5m';     S_REVERSE=$'\033[7m'
    S_RESET=$'\033[0m'
else
    C_BLACK=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
    C_MAGENTA=''; C_CYAN=''; C_WHITE=''; C_BRIGHT_BLACK=''
    C_BRIGHT_RED=''; C_BRIGHT_GREEN=''; C_BRIGHT_YELLOW=''
    C_BRIGHT_BLUE=''; C_BRIGHT_MAGENTA=''; C_BRIGHT_CYAN=''; C_BRIGHT_WHITE=''
    B_BLACK=''; B_MAGENTA=''; B_CYAN=''; B_WHITE=''; B_BRIGHT_BLACK=''
    B_BRIGHT_BLUE=''; B_BRIGHT_MAGENTA=''; B_BRIGHT_CYAN=''
    S_BOLD=''; S_DIM=''; S_ITALIC=''; S_UNDERLINE=''
    S_BLINK=''; S_REVERSE=''; S_RESET=''
fi

# --- Terminal Utilities ------------------------------------
term_width()  { tput cols  2>/dev/null || echo 80; }
term_height() { tput lines 2>/dev/null || echo 24; }
cursor_hide() { printf '\033[?25l'; }
cursor_show() { printf '\033[?25h'; }
cursor_move() { printf '\033[%d;%dH' "$1" "$2"; }  # row col
clear_screen() { printf '\033[2J\033[H'; }
clear_line()   { printf '\033[2K\r'; }

# Trap to always restore terminal on exit
_tui_cleanup() {
    cursor_show
    printf '\033[?1049l'  # switch back from alt screen if used
    stty echo 2>/dev/null || true
    tput cnorm 2>/dev/null || true
}
trap _tui_cleanup EXIT INT TERM

# --- Drawing Primitives ------------------------------------
# Box characters
TL='+'; TR='+'; BL='+'; BR='+'; H='-'; V='|'
TLC='+'; TRC='+'; TT='+'; TB='+'; CROSS='+'
tl='+'; tr='+'; bl='+'; br='+'; h='-'; v='|'
tlc='+'; trc='+'; tt='+'; tb='+'; cross='+'

# Draw a box: draw_box row col width height [border_color] [fill_color]
draw_box() {
    local row="$1" col="$2" w="$3" h_box="$4"
    local bc="${5:-$C_BRIGHT_BLACK}" fc="${6:-}"
    local inner_w=$(( w - 2 ))
    local sep
    sep=$(printf '%*s' "$inner_w" '' | tr ' ' "$H")

    # Top border
    cursor_move "$row" "$col"
    printf '%s%s%s%s%s%s' "$bc" "$TL" "$sep" "$TR" "$S_RESET" ""

    # Side borders + optional fill
    local r
    for (( r = row + 1; r < row + h_box - 1; r++ )); do
        cursor_move "$r" "$col"
        printf '%s%s' "$bc" "$V"
        if [ -n "$fc" ]; then
            printf '%s%*s' "$fc" "$inner_w" ''
        else
            printf '%*s' "$inner_w" ''
        fi
        printf '%s%s%s' "$bc" "$V" "$S_RESET"
    done

    # Bottom border
    local bot_sep
    bot_sep=$(printf '%*s' "$inner_w" '' | tr ' ' "$H")
    cursor_move $(( row + h_box - 1 )) "$col"
    printf '%s%s%s%s%s' "$bc" "$BL" "$bot_sep" "$BR" "$S_RESET"
}

# Draw a thin box
draw_thin_box() {
    local row="$1" col="$2" w="$3" h_box="$4"
    local bc="${5:-$C_BRIGHT_BLACK}" fc="${6:-}"
    local inner_w=$(( w - 2 ))
    local sep
    sep=$(printf '%*s' "$inner_w" '' | tr ' ' "$h")

    cursor_move "$row" "$col"
    printf '%s%s%s%s%s' "$bc" "$tl" "$sep" "$tr" "$S_RESET"

    local r
    for (( r = row + 1; r < row + h_box - 1; r++ )); do
        cursor_move "$r" "$col"
        printf '%s%s' "$bc" "$v"
        if [ -n "$fc" ]; then
            printf '%s%*s' "$fc" "$inner_w" ''
        else
            printf '%*s' "$inner_w" ''
        fi
        printf '%s%s%s' "$bc" "$v" "$S_RESET"
    done

    local bot_sep
    bot_sep=$(printf '%*s' "$inner_w" '' | tr ' ' "$h")
    cursor_move $(( row + h_box - 1 )) "$col"
    printf '%s%s%s%s%s' "$bc" "$bl" "$bot_sep" "$br" "$S_RESET"
}

# Print centered text within a column range
print_centered() {
    local row="$1" col_start="$2" width="$3" text="$4" color="${5:-}"
    # Strip ANSI for length calculation
    local plain
    plain=$(printf '%s' "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#plain}
    local pad=$(( (width - text_len) / 2 ))
    cursor_move "$row" $(( col_start + pad ))
    printf '%s%s%s' "$color" "$text" "$S_RESET"
}

# Print left-aligned text inside a box (accounts for border)
print_in_box() {
    local row="$1" col="$2" text="$3" color="${4:-}"
    cursor_move "$row" $(( col + 2 ))
    printf '%s%s%s' "$color" "$text" "$S_RESET"
}

# --- ASCII Art ---------------------------------------------
LOGO=(
    "  _____ _    _  ___  _   _ _____  _   _  __   __"
    " / ____| |  | |/ _ \| \ | | ____|| \ | | \ \ / /"
    "| (___ | |__| | | | |  \| | |__  |  \| |  \ V / "
    " \___ \|  __  | | | | . \` |  __| | . \` |   > <  "
    " ____) | |  | | |_| | |\  | |____| |\  |  / . \ "
    "|_____/|_|  |_|\___/|_| \_|______|_| \_| /_/ \_\ "
)

# --- Status / Log Line -------------------------------------
LOG_ROW=0
LOG_COL=0
LOG_WIDTH=0

tui_log() {
    local level="$1"; shift
    local msg="$*"
    local icon color
    case "$level" in
        info)    icon="  "; color="$C_BRIGHT_CYAN" ;;
        ok)      icon="[ok] "; color="$C_BRIGHT_GREEN" ;;
        warn)    icon="[!!] "; color="$C_BRIGHT_YELLOW" ;;
        err)     icon="[!!] "; color="$C_BRIGHT_RED" ;;
        step)    icon=">> "; color="$C_BRIGHT_MAGENTA" ;;
        *)       icon="  "; color="$C_WHITE" ;;
    esac
    if [ "$LOG_ROW" -gt 0 ]; then
        cursor_move "$LOG_ROW" $(( LOG_COL + 1 ))
        printf '%s%s%-*s%s' "$color" "$icon$msg" $(( LOG_WIDTH - ${#icon} - ${#msg} - 2 )) '' "$S_RESET"
    else
        printf '%s%s%s%s\n' "$color" "$icon" "$msg" "$S_RESET"
    fi
}

# --- Progress Bar ------------------------------------------
# progress_bar row col width pct label
progress_bar() {
    local row="$1" col="$2" width="$3" pct="$4" label="${5:-}"
    local bar_w=$(( width - 10 ))
    local filled=$(( bar_w * pct / 100 ))
    local empty=$(( bar_w - filled ))
    local bar_fill
    bar_fill=$(printf '%*s' "$filled" '' | tr ' ' '#')
    local bar_empty
    bar_empty=$(printf '%*s' "$empty" '' | tr ' ' '.')

    cursor_move "$row" "$col"
    printf '%s[%s%s%s%s%s] %3d%%%s' \
        "$C_BRIGHT_BLACK" \
        "$C_BRIGHT_CYAN" "$bar_fill" \
        "$C_BRIGHT_BLACK" "$bar_empty" \
        "$C_BRIGHT_BLACK" \
        "$pct" \
        "$S_RESET"

    if [ -n "$label" ]; then
        cursor_move $(( row + 1 )) "$col"
        printf '%s%-*s%s' "$S_DIM" "$width" "$label" "$S_RESET"
    fi
}

# --- Spinner -----------------------------------------------
SPINNER_FRAMES=('|' '/' '-' '\\')
SPINNER_IDX=0
SPINNER_PID=0

spinner_start() {
    local row="$1" col="$2" label="${3:-Working...}"
    SPINNER_IDX=0
    (
        while true; do
            local f="${SPINNER_FRAMES[$((SPINNER_IDX % ${#SPINNER_FRAMES[@]}))]}"
            cursor_move "$row" "$col"
            printf '%s%s %s%s' "$C_BRIGHT_CYAN" "$f" "$label" "$S_RESET"
            (( SPINNER_IDX++ )) || true
            sleep 0.08
        done
    ) &
    SPINNER_PID=$!
}

spinner_stop() {
    if [ "$SPINNER_PID" -gt 0 ]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=0
    fi
}

# --- Input Prompt ------------------------------------------
# tui_prompt row col width prompt default > sets REPLY
tui_prompt() {
    local row="$1" col="$2" width="$3" prompt="$4" default="${5:-}"
    cursor_move "$row" "$col"
    printf '%s%s%s' "$S_BOLD" "$prompt" "$S_RESET"
    if [ -n "$default" ]; then
        printf ' %s[%s]%s' "$S_DIM" "$default" "$S_RESET"
    fi
    printf ': '
    cursor_show
    stty echo
    read -r REPLY || true
    cursor_hide
    stty -echo 2>/dev/null || true
    if [ -z "$REPLY" ] && [ -n "$default" ]; then
        REPLY="$default"
    fi
}

# --- Key Reading -------------------------------------------
read_key() {
    local key
    IFS= read -r -s -n1 key 2>/dev/null || true
    if [ "$key" = $'\x1b' ]; then
        local extra
        IFS= read -r -s -n2 -t 0.1 extra 2>/dev/null || true
        key="$key$extra"
    fi
    KEY="$key"
}

# --- Notification ------------------------------------------
# show_notification row col width msg type (ok|warn|err|info)
show_notification() {
    local row="$1" col="$2" width="$3" msg="$4" type="${5:-info}"
    local color icon
    case "$type" in
        ok)   color="$C_BRIGHT_GREEN";   icon="[ok]" ;;
        warn) color="$C_BRIGHT_YELLOW";  icon="[!!]" ;;
        err)  color="$C_BRIGHT_RED";     icon="[!!]" ;;
        *)    color="$C_BRIGHT_CYAN";    icon="[i]" ;;
    esac
    cursor_move "$row" "$col"
    printf '%s %s  %s%-*s%s' \
        "$color" "$icon" "$S_RESET" \
        $(( width - 4 )) "$msg" "$S_RESET"
}

# --- Banner Screen -----------------------------------------
show_banner() {
    local W; W=$(term_width)
    clear_screen
    cursor_hide

    # Thin rule above logo
    local rule
    rule=$(printf '%*s' 63 '' | tr ' ' '-')
    local rule_pad=$(( (W - 63) / 2 ))
    cursor_move 2 $(( rule_pad > 1 ? rule_pad : 1 ))
    printf '%s%s%s' "$C_BRIGHT_BLACK" "$rule" "$S_RESET"

    # Logo -- centered, magenta
    local logo_start_row=3
    for i in "${!LOGO[@]}"; do
        local line="${LOGO[$i]}"
        local pad=$(( (W - ${#line}) / 2 ))
        cursor_move $(( logo_start_row + i )) $(( pad > 1 ? pad : 1 ))
        printf '%s%s%s' "$C_BRIGHT_MAGENTA" "$line" "$S_RESET"
    done

    # Thin rule below logo
    cursor_move $(( logo_start_row + ${#LOGO[@]} )) $(( rule_pad > 1 ? rule_pad : 1 ))
    printf '%s%s%s' "$C_BRIGHT_BLACK" "$rule" "$S_RESET"

    # Subtitle
    local subtitle="Ultimate Anime & Manga Client"
    local sub_pad=$(( (W - ${#subtitle}) / 2 ))
    cursor_move $(( logo_start_row + ${#LOGO[@]} + 1 )) $(( sub_pad > 1 ? sub_pad : 1 ))
    printf '%s%s%s' "$S_DIM" "$subtitle" "$S_RESET"
}

# --- Main Menu ---------------------------------------------
MENU_ITEMS=(
    ">>  Quick Install / Update    Install latest release with defaults"
    "##   Custom Installation       Choose custom repo, fork, or icon"
    "??  System Status             View installed paths & integrations"
    "**  Setup Shell Command       Install shonenx-manager shortcut"
    "xx   Uninstall ShonenX        Remove binary, data & shortcuts"
    "--  Exit"
)
MENU_ICONS=(">>" "## " "??" "**" "xx " "--")
MENU_LABELS=("Quick Install / Update" "Custom Installation" "System Status" "Setup Shell Command" "Uninstall ShonenX" "Exit")
MENU_DESCS=(
    "Install latest release with defaults"
    "Choose custom repo, fork, or icon"
    "View installed paths & integrations"
    "Install shonenx-manager shortcut"
    "Remove binary, data & shortcuts"
    ""
)

draw_menu() {
    local selected="$1"
    local W; W=$(term_width)
    local H; H=$(term_height)
    local count=${#MENU_LABELS[@]}

    # Menu box: starts at row 13, width = W-4, col 3
    local box_col=3
    local box_w=$(( W - 6 ))
    local box_row=12
    local box_h=$(( count * 2 + 3 ))  # header + items + padding

    # Draw the box once per full redraw
    draw_thin_box "$box_row" "$box_col" "$box_w" "$box_h" "$C_BRIGHT_BLACK"

    # Box title
    cursor_move "$box_row" $(( box_col + 2 ))
    printf '%s MENU %s' "$C_BRIGHT_BLACK" "$S_RESET"

    local inner_w=$(( box_w - 4 ))
    local label_w=24
    local desc_w=$(( inner_w - label_w - 12 ))

    for (( i = 0; i < count; i++ )); do
        local item_row=$(( box_row + 1 + i * 2 ))
        local icon="${MENU_ICONS[$i]}"
        local label="${MENU_LABELS[$i]}"
        local desc="${MENU_DESCS[$i]:-}"
        if [ "${#desc}" -gt "$desc_w" ]; then
            desc="${desc:0:$(( desc_w - 3 ))}..."
        fi
        local num=$(( i + 1 ))

        # Clear the two lines for this item
        cursor_move "$item_row" $(( box_col + 1 ))
        printf '%*s' $(( box_w - 2 )) ''
        cursor_move $(( item_row + 1 )) $(( box_col + 1 ))
        printf '%*s' $(( box_w - 2 )) ''

        if [ "$i" -eq "$selected" ]; then
            # Highlighted: full-width inverted row
            cursor_move "$item_row" $(( box_col + 1 ))
            printf '%s%s' "$S_REVERSE" "$C_BRIGHT_MAGENTA"
            printf ' %s  %s  %-*s  %s%-*s ' \
                "$num" "$icon" \
                "$label_w" "$label" \
                "" "$desc_w" "$desc"
            printf '%s' "$S_RESET"
        else
            cursor_move "$item_row" $(( box_col + 2 ))
            # Number (dim)
            printf '%s%s%s' "$S_DIM" "$num" "$S_RESET"
            printf '  %s  ' "$icon"
            # Label (white)
            printf '%s%-*s%s' "$C_WHITE" "$label_w" "$label" "$S_RESET"
            printf '  '
            # Description (dim)
            printf '%s%-*s%s' "$S_DIM" "$desc_w" "$desc" "$S_RESET"
        fi
    done

    # Footer
    local footer_row=$(( H - 2 ))
    cursor_move "$footer_row" "$box_col"
    printf '%s  ^v / jk  Navigate    Enter  Select    q  Quit%s' "$S_DIM" "$S_RESET"
}

update_menu_descriptions() {
    if [ "$REPO" != "$DEFAULT_REPO" ] || [ "$ICON_INPUT" != "$DEFAULT_ICON_URL" ]; then
        if [ "$REPO" != "$DEFAULT_REPO" ]; then
            MENU_DESCS[0]="Install latest release (cached: $REPO)"
        else
            MENU_DESCS[0]="Install latest release (cached custom icon)"
        fi
    else
        MENU_DESCS[0]="Install latest release with defaults"
    fi
}

run_menu() {
    local selected=0
    local count=${#MENU_LABELS[@]}

    show_banner

    while true; do
        update_menu_descriptions
        draw_menu "$selected"
        read_key
        case "$KEY" in
            $'\x1b[A'|k|K)  # Up
                (( selected-- )) || true
                [ "$selected" -lt 0 ] && selected=$(( count - 1 ))
                ;;
            $'\x1b[B'|j|J)  # Down
                (( selected++ )) || true
                [ "$selected" -ge "$count" ] && selected=0
                ;;
            1) selected=0; dispatch_action 0 ;;
            2) selected=1; dispatch_action 1 ;;
            3) selected=2; dispatch_action 2 ;;
            4) selected=3; dispatch_action 3 ;;
            5) selected=4; dispatch_action 4 ;;
            6|q|Q) dispatch_action 5 ;;
            $'\n'|$'\r'|'')
                dispatch_action "$selected"
                ;;
        esac
    done
}

dispatch_action() {
    case "$1" in
        0) tui_install ;;
        1) tui_custom_install ;;
        2) tui_status ;;
        3) tui_setup_manager_screen ;;
        4) tui_uninstall ;;
        5) tui_exit ;;
    esac
}

# --- Sub-screen frame --------------------------------------
draw_subscreen() {
    local title="$1"
    local W; W=$(term_width)
    local H; H=$(term_height)
    clear_screen
    cursor_hide

    # Top rule + title
    local rule
    rule=$(printf '%*s' $(( W - 2 )) '' | tr ' ' '-')
    cursor_move 1 1
    printf '%s%s%s' "$C_BRIGHT_BLACK" "$rule" "$S_RESET"
    cursor_move 2 3
    printf '%s%s%s' "$S_BOLD" "$title" "$S_RESET"

    # Divider below title
    cursor_move 3 1
    printf '%s%s%s' "$C_BRIGHT_BLACK" "$rule" "$S_RESET"

    # Bottom rule + hint
    cursor_move $(( H - 2 )) 1
    printf '%s%s%s' "$C_BRIGHT_BLACK" "$rule" "$S_RESET"
    cursor_move $(( H - 1 )) 3
    printf '%s< any key to return%s' "$S_DIM" "$S_RESET"
}

# --- Scrolling Log Panel -----------------------------------
LOG_LINES=()
LOG_PANEL_ROW=4
LOG_PANEL_COL=2
LOG_PANEL_WIDTH=0
LOG_PANEL_HEIGHT=0

log_panel_init() {
    local W; W=$(term_width)
    local H; H=$(term_height)
    LOG_PANEL_WIDTH=$(( W - 4 ))
    LOG_PANEL_HEIGHT=$(( H - 8 ))
    LOG_LINES=()
}

log_panel_add() {
    local level="$1"; shift
    local msg="$*"
    local icon color
    case "$level" in
        ok)   icon="[ok]"; color="$C_BRIGHT_GREEN" ;;
        warn) icon="[!!]"; color="$C_BRIGHT_YELLOW" ;;
        err)  icon="[!!]"; color="$C_BRIGHT_RED" ;;
        step) icon=">>"; color="$C_BRIGHT_MAGENTA" ;;
        *)    icon="-"; color="$C_BRIGHT_CYAN" ;;
    esac
    LOG_LINES+=( "${color}${icon} ${msg}${S_RESET}" )
    log_panel_redraw
}

log_panel_redraw() {
    local W; W=$(term_width)
    local H; H=$(term_height)
    local panel_w=$(( W - 4 ))
    local panel_h=$(( H - 8 ))
    local panel_row=4
    local panel_col=3

    # Clear panel area
    for (( r = panel_row; r < panel_row + panel_h; r++ )); do
        cursor_move "$r" "$panel_col"
        printf '%*s' "$panel_w" ''
    done

    # Print last N lines that fit
    local total=${#LOG_LINES[@]}
    local start=$(( total - panel_h ))
    [ "$start" -lt 0 ] && start=0

    local display_row="$panel_row"
    for (( i = start; i < total; i++ )); do
        cursor_move "$display_row" "$panel_col"
        # Truncate long lines
        local line="${LOG_LINES[$i]}"
        local plain
        plain=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
        if [ "${#plain}" -gt "$panel_w" ]; then
            line="${line:0:$panel_w}"
        fi
        printf '%s' "$line"
        (( display_row++ )) || true
    done
}

# --- Core Logic Functions ----------------------------------
check_mpv() {
    local has_mpv=0
    if ldconfig -p 2>/dev/null | grep -q "libmpv"; then has_mpv=1; fi
    if [ -f /usr/lib/libmpv.so ] || [ -f /usr/lib64/libmpv.so ] || \
       [ -f /usr/local/lib/libmpv.so ] || [ -f "${PREFIX:-}/lib/libmpv.so" ]; then
        has_mpv=1
    fi
    command -v mpv >/dev/null 2>&1 && has_mpv=1

    if [ "$has_mpv" -eq 0 ]; then
        log_panel_add info "libmpv not found -- installing system dependency..."
        if $IS_TERMUX && command -v pkg >/dev/null 2>&1; then
            pkg install -y mpv >/dev/null 2>&1
        elif command -v pacman >/dev/null 2>&1; then
            $SUDO pacman -Sy --noconfirm mpv >/dev/null 2>&1
        elif command -v apt-get >/dev/null 2>&1; then
            $SUDO apt-get update -qq && ($SUDO apt-get install -y libmpv-dev >/dev/null 2>&1 || $SUDO apt-get install -y mpv >/dev/null 2>&1)
        elif command -v dnf >/dev/null 2>&1; then
            ($SUDO dnf install -y mpv-libs >/dev/null 2>&1 || $SUDO dnf install -y mpv >/dev/null 2>&1)
        elif command -v zypper >/dev/null 2>&1; then
            ($SUDO zypper install -y libmpv1 >/dev/null 2>&1 || $SUDO zypper install -y mpv >/dev/null 2>&1)
        else
            log_panel_add warn "Could not auto-install mpv. Install it manually."
            return
        fi
        log_panel_add ok "mpv installed"
    else
        log_panel_add ok "mpv/libmpv detected"
    fi
}

setup_path() {
    $IS_TERMUX && return
    [[ ":$PATH:" == *":$BIN_DIR:"* ]] && return

    log_panel_add warn "$BIN_DIR is not in PATH -- updating shell configs..."
    [ -f "$HOME/.bashrc" ] && ! grep -q "$BIN_DIR" "$HOME/.bashrc" && \
        printf '\nexport PATH="$PATH:%s"\n' "$BIN_DIR" >> "$HOME/.bashrc" && \
        log_panel_add ok "Updated ~/.bashrc"
    [ -f "$HOME/.zshrc" ] && ! grep -q "$BIN_DIR" "$HOME/.zshrc" && \
        printf '\nexport PATH="$PATH:%s"\n' "$BIN_DIR" >> "$HOME/.zshrc" && \
        log_panel_add ok "Updated ~/.zshrc"
    if [ -d "$HOME/.config/fish" ]; then
        mkdir -p "$HOME/.config/fish"
        touch "$HOME/.config/fish/config.fish"
        if ! grep -q "$BIN_DIR" "$HOME/.config/fish/config.fish"; then
            printf '\n# ShonenX Path\nfish_add_path %s\n' "$BIN_DIR" >> "$HOME/.config/fish/config.fish"
            log_panel_add ok "Updated fish config"
        fi
    fi
    log_panel_add warn "Restart your shell to apply PATH changes"
}

update_shell_config() {
    local cfg="$1"
    [ -f "$cfg" ] || return
    grep -q "# --- ShonenX Manager Start ---" "$cfg" && \
        sed -i '/# --- ShonenX Manager Start ---/,/# --- ShonenX Manager End ---/d' "$cfg"
    cat << EOF >> "$cfg"

# --- ShonenX Manager Start ---
shonenx-manager() {
    local url="https://raw.githubusercontent.com/${REPO}/main/install.sh"
    local tmp="/tmp/shonenx_install_latest.sh"
    echo -e "\033[0;36m\033[1m[*] Fetching latest ShonenX Manager...\033[0m"
    if curl -sSL --connect-timeout 10 "\$url" -o "\$tmp" && [ -s "\$tmp" ]; then
        bash "\$tmp" "\$@"
    else
        echo -e "\033[0;31m[[!!]] Failed to fetch installer.\033[0m"; return 1
    fi
}
# --- ShonenX Manager End ---
EOF
}

setup_fish_function() {
    command -v fish >/dev/null 2>&1 || [ -d "$HOME/.config/fish" ] || return
    local fish_dir="$HOME/.config/fish/functions"
    mkdir -p "$fish_dir"
    cat << EOF > "$fish_dir/shonenx-manager.fish"
function shonenx-manager --description "ShonenX Remote Launcher"
    set -l url "https://raw.githubusercontent.com/${REPO}/main/install.sh"
    set -l tmp "/tmp/shonenx_install_latest.sh"
    if curl -sSL --connect-timeout 10 "\$url" -o "\$tmp"; and test -s "\$tmp"
        bash "\$tmp" \$argv
    else
        echo -e "\033[0;31m[[!!]] Failed to fetch installer.\033[0m"; return 1
    end
end
EOF
}

do_install() {
    local target_tag="${1:-}"
    check_mpv

    log_panel_add step "Querying GitHub releases for $REPO..."
    local release_json
    if [ -n "$target_tag" ] && [ "$target_tag" != "latest" ]; then
        log_panel_add step "Fetching release $target_tag..."
        release_json=$(curl -s "https://api.github.com/repos/$REPO/releases/tags/$target_tag")
    else
        release_json=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
    fi

    if echo "$release_json" | grep -q '"message": "Not Found"'; then
        log_panel_add err "Repository '$REPO' not found or has no releases"
        return 1
    fi

    local download_url version
    download_url=$(echo "$release_json" | grep -o '"browser_download_url": "[^"]*' | grep -i "linux" | sed 's/"browser_download_url": "//' | head -n 1)
    version=$(echo "$release_json" | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//' | head -n 1)

    if [ -z "$download_url" ]; then
        log_panel_add err "No Linux asset found in release $version"
        return 1
    fi

    log_panel_add ok "Latest version: $version"
    log_panel_add step "Downloading bundle from GitHub..."

    local tmp_zip="/tmp/shonenx.zip"
    curl -L --silent "$download_url" -o "$tmp_zip"
    log_panel_add ok "Download complete"

    log_panel_add step "Extracting files to $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR"
    unzip -q -o "$tmp_zip" -d "$INSTALL_DIR"
    rm -f "$tmp_zip"

    [ -d "$INSTALL_DIR/linux" ] && find "$INSTALL_DIR/linux" -maxdepth 1 -mindepth 1 -exec mv -t "$INSTALL_DIR" {} + && rmdir "$INSTALL_DIR/linux"

    local exe_path
    exe_path=$(find "$INSTALL_DIR" -type f -name "$EXE_NAME" | head -n 1)
    if [ -z "$exe_path" ]; then
        log_panel_add err "Executable '$EXE_NAME' not found in archive"
        return 1
    fi
    chmod +x "$exe_path"
    mkdir -p "$BIN_DIR"
    ln -sf "$exe_path" "$BIN_DIR/$EXE_NAME"
    log_panel_add ok "Linked: $BIN_DIR/$EXE_NAME > $exe_path"

    if [ -n "$DESKTOP_DIR" ]; then
        log_panel_add step "Setting up desktop integration..."
        mkdir -p "$ICON_DIR" "$DESKTOP_DIR"
        local expanded_icon="${ICON_INPUT/#\~/$HOME}"
        if [ -f "$expanded_icon" ]; then
            cp -f "$expanded_icon" "$ICON_DIR/shonenx.png" && log_panel_add ok "Icon copied from local path"
        elif [[ "$ICON_INPUT" =~ ^https?:// ]]; then
            curl -sL "$ICON_INPUT" -o "$ICON_DIR/shonenx.png" && log_panel_add ok "Icon downloaded"
        fi
        cat > "$DESKTOP_DIR/shonenx.desktop" <<EOF
[Desktop Entry]
Version=1.0
Name=ShonenX
Comment=Anilist & MAL Client for Anime and Manga
Exec=$BIN_DIR/$EXE_NAME %u
Icon=$ICON_DIR/shonenx.png
Terminal=false
Type=Application
Categories=Network;Entertainment;
MimeType=x-scheme-handler/shonenx;x-scheme-handler/aniyomi;x-scheme-handler/tachiyomi;x-scheme-handler/cloudstream;x-scheme-handler/cloudstreamrepo;x-scheme-handler/kotatsu;x-scheme-handler/sora;
EOF
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
        log_panel_add ok "Desktop entry created"
    fi

    setup_path
    # Silent manager refresh
    do_manager_quiet
    save_cache
    log_panel_add ok "ShonenX $version installed -- run: $EXE_NAME"
}

do_manager() {
    log_panel_add step "Installing shonenx-manager binary..."
    mkdir -p "$BIN_DIR"
    local manager_path="$BIN_DIR/shonenx-manager"
    cat << EOF > "$manager_path"
#!/usr/bin/env bash
set -euo pipefail
URL="https://raw.githubusercontent.com/${REPO}/main/install.sh"
TMP="/tmp/shonenx_install_latest.sh"
echo -e "\033[0;36m\033[1m[*] Fetching latest ShonenX Manager...\033[0m"
if curl -sSL --connect-timeout 10 "\$URL" -o "\$TMP" && [ -s "\$TMP" ]; then
    bash "\$TMP" "\$@"
else
    echo -e "\033[0;31m[[!!]] Failed to fetch installer.\033[0m"; exit 1
fi
EOF
    chmod +x "$manager_path"
    log_panel_add ok "Binary: $manager_path"

    [ -f "$HOME/.bashrc" ] && update_shell_config "$HOME/.bashrc" && log_panel_add ok "Updated ~/.bashrc"
    [ -f "$HOME/.zshrc" ]  && update_shell_config "$HOME/.zshrc"  && log_panel_add ok "Updated ~/.zshrc"
    setup_fish_function && log_panel_add ok "Fish function configured"
    setup_path
    log_panel_add ok "shonenx-manager is ready across all shells"
}

do_manager_quiet() {
    mkdir -p "$BIN_DIR"
    local manager_path="$BIN_DIR/shonenx-manager"
    cat << EOF > "$manager_path"
#!/usr/bin/env bash
set -euo pipefail
URL="https://raw.githubusercontent.com/${REPO}/main/install.sh"
TMP="/tmp/shonenx_install_latest.sh"
echo -e "\033[0;36m\033[1m[*] Fetching latest ShonenX Manager...\033[0m"
if curl -sSL --connect-timeout 10 "\$URL" -o "\$TMP" && [ -s "\$TMP" ]; then
    bash "\$TMP" "\$@"
else
    echo -e "\033[0;31m[[!!]] Failed to fetch installer.\033[0m"; exit 1
fi
EOF
    chmod +x "$manager_path"
    [ -f "$HOME/.config/fish/functions/shonenx-manager.fish" ] && setup_fish_function >/dev/null 2>&1 || true
}

do_uninstall() {
    log_panel_add step "Removing application directory..."
    rm -rf "$INSTALL_DIR" && log_panel_add ok "Removed $INSTALL_DIR"
    rm -f "$CACHE_FILE" && rmdir "$CACHE_DIR" 2>/dev/null || true
    rm -f "$BIN_DIR/$EXE_NAME"    && log_panel_add ok "Removed binary"
    rm -f "$BIN_DIR/shonenx-manager" && log_panel_add ok "Removed shonenx-manager"

    if [ -n "$DESKTOP_DIR" ]; then
        rm -f "$DESKTOP_DIR/shonenx.desktop"
        rm -f "$ICON_DIR/shonenx.png"
        command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" || true
        log_panel_add ok "Removed desktop entry & icon"
    fi

    for cfg in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$cfg" ] && grep -q "# --- ShonenX Manager Start ---" "$cfg"; then
            sed -i '/# --- ShonenX Manager Start ---/,/# --- ShonenX Manager End ---/d' "$cfg"
            log_panel_add ok "Cleaned $cfg"
        fi
    done

    rm -f "$HOME/.config/fish/functions/shonenx-manager.fish" && log_panel_add ok "Removed fish function"
    log_panel_add ok "ShonenX fully uninstalled"
}

# --- Release Selector --------------------------------------
SELECTED_RELEASE_TAG=""

tui_select_release() {
    local target_repo="$1"
    draw_subscreen "  >>  SELECT RELEASE TO INSTALL"
    local W; W=$(term_width)
    local H; H=$(term_height)

    cursor_move 5 3
    printf '%s[*] Fetching available releases from %s...%s' "$C_BRIGHT_CYAN" "$target_repo" "$S_RESET"

    local releases_json
    releases_json=$(curl -s "https://api.github.com/repos/$target_repo/releases?per_page=10")

    # Clear loading message
    cursor_move 5 3
    printf '%*s' $(( W - 6 )) ''

    # Parse releases
    local parsed
    if command -v jq >/dev/null 2>&1; then
        parsed=$(echo "$releases_json" | jq -r '.[] | "\(.tag_name)\t\(.prerelease)\t\(.name)"' 2>/dev/null || true)
    elif command -v python3 >/dev/null 2>&1; then
        parsed=$(python3 -c '
import sys, json
try:
    for r in json.load(sys.stdin):
        print(f"{r.get(\"tag_name\",\"\")}\t{r.get(\"prerelease\",False)}\t{r.get(\"name\",\"\")}")
except Exception:
    pass
' <<< "$releases_json" || true)
    else
        parsed=$(echo "$releases_json" | grep -E '"tag_name":|"prerelease":|"name":' | awk '
        /"tag_name":/ { tag=$2; gsub(/["|,]/, "", tag); }
        /"prerelease":/ { pre=$2; gsub(/["|,]/, "", pre); }
        /"name":/ {
            name=$0; sub(/[^"]*"name": *"/, "", name); sub(/".*/, "", name);
            if (tag != "") { print tag "\t" pre "\t" name; tag=""; pre=""; }
        }' || true)
    fi

    if [ -z "$parsed" ]; then
        cursor_move 5 3
        printf '%s[!!] Could not fetch releases list. Defaulting to latest stable...%s' "$C_BRIGHT_YELLOW" "$S_RESET"
        sleep 1.5
        SELECTED_RELEASE_TAG="latest"
        return 0
    fi

    local tags=() pres=() names=()
    while IFS=$'\t' read -r t p n; do
        if [ -n "$t" ]; then
            tags+=("$t")
            pres+=("$p")
            names+=("$n")
        fi
    done <<< "$parsed"

    local count=${#tags[@]}
    if [ "$count" -eq 0 ]; then
        SELECTED_RELEASE_TAG="latest"
        return 0
    fi

    local selected=0
    local box_col=3
    local box_w=$(( W - 6 ))
    local box_row=5
    local box_h=$(( count * 2 + 3 ))

    draw_thin_box "$box_row" "$box_col" "$box_w" "$box_h" "$C_BRIGHT_BLACK"
    cursor_move "$box_row" $(( box_col + 2 ))
    printf '%s AVAILABLE RELEASES %s' "$C_BRIGHT_BLACK" "$S_RESET"

    local inner_w=$(( box_w - 4 ))
    local badge_w=17
    local tag_w=15
    local name_w=$(( inner_w - badge_w - tag_w - 8 ))
    [ "$name_w" -lt 10 ] && name_w=10

    while true; do
        for (( i = 0; i < count; i++ )); do
            local item_row=$(( box_row + 1 + i * 2 ))
            local tag="${tags[$i]}"
            local pre="${pres[$i]}"
            local name="${names[$i]:-}"
            [ "${#name}" -gt "$name_w" ] && name="${name:0:$(( name_w - 3 ))}..."

            local badge="" badge_color="$C_BRIGHT_GREEN"
            if [ "$i" -eq 0 ]; then
                if [ "$pre" = "true" ] || [ "$pre" = "True" ] || [ "$pre" = "1" ]; then
                    badge="[Latest Pre-rel]"
                    badge_color="$C_BRIGHT_YELLOW"
                else
                    badge="[Latest Stable]"
                    badge_color="$C_BRIGHT_GREEN"
                fi
            else
                if [ "$pre" = "true" ] || [ "$pre" = "True" ] || [ "$pre" = "1" ]; then
                    badge="[Pre-release]"
                    badge_color="$C_BRIGHT_YELLOW"
                else
                    badge="[Stable]"
                    badge_color="$C_CYAN"
                fi
            fi

            local num=$(( i + 1 ))
            cursor_move "$item_row" $(( box_col + 1 ))
            printf '%*s' $(( box_w - 2 )) ''
            cursor_move $(( item_row + 1 )) $(( box_col + 1 ))
            printf '%*s' $(( box_w - 2 )) ''

            if [ "$i" -eq "$selected" ]; then
                cursor_move "$item_row" $(( box_col + 1 ))
                printf '%s%s' "$S_REVERSE" "$C_BRIGHT_MAGENTA"
                printf ' %s  %-*s  %-*s  %-*s ' \
                    "$num" "$badge_w" "$badge" "$tag_w" "$tag" "$name_w" "$name"
                printf '%s' "$S_RESET"
            else
                cursor_move "$item_row" $(( box_col + 2 ))
                printf '%s%s%s  ' "$S_DIM" "$num" "$S_RESET"
                printf '%s%-*s%s  ' "$badge_color" "$badge_w" "$badge" "$S_RESET"
                printf '%s%-*s%s  ' "$C_BRIGHT_WHITE" "$tag_w" "$tag" "$S_RESET"
                printf '%s%-*s%s' "$S_DIM" "$name_w" "$name" "$S_RESET"
            fi
        done

        local footer_row=$(( H - 2 ))
        cursor_move "$footer_row" "$box_col"
        printf '%*s' "$box_w" ''
        cursor_move "$footer_row" "$box_col"
        printf '%s  ^v / jk  Navigate    Enter  Select (%s)    q  Cancel%s' "$S_DIM" "${tags[$selected]}" "$S_RESET"

        read_key
        case "$KEY" in
            $'\x1b[A'|k|K)
                (( selected-- )) || true
                [ "$selected" -lt 0 ] && selected=$(( count - 1 ))
                ;;
            $'\x1b[B'|j|J)
                (( selected++ )) || true
                [ "$selected" -ge "$count" ] && selected=0
                ;;
            1) [ "$count" -ge 1 ] && { selected=0; break; } ;;
            2) [ "$count" -ge 2 ] && { selected=1; break; } ;;
            3) [ "$count" -ge 3 ] && { selected=2; break; } ;;
            4) [ "$count" -ge 4 ] && { selected=3; break; } ;;
            5) [ "$count" -ge 5 ] && { selected=4; break; } ;;
            6) [ "$count" -ge 6 ] && { selected=5; break; } ;;
            7) [ "$count" -ge 7 ] && { selected=6; break; } ;;
            8) [ "$count" -ge 8 ] && { selected=7; break; } ;;
            9) [ "$count" -ge 9 ] && { selected=8; break; } ;;
            q|Q|$'\x1b') return 1 ;;
            $'\n'|$'\r'|'') break ;;
        esac
    done

    SELECTED_RELEASE_TAG="${tags[$selected]}"
    return 0
}

# --- TUI Screens -------------------------------------------
tui_install() {
    if ! tui_select_release "$REPO"; then
        show_banner
        return
    fi
    draw_subscreen "  >>  QUICK INSTALL / UPDATE"
    log_panel_init
    if [ "$REPO" != "$DEFAULT_REPO" ] || [ "$ICON_INPUT" != "$DEFAULT_ICON_URL" ]; then
        log_panel_add info "Using cached custom configuration"
    fi
    if [ "$SELECTED_RELEASE_TAG" != "latest" ] && [ -n "$SELECTED_RELEASE_TAG" ]; then
        log_panel_add info "Selected release : $SELECTED_RELEASE_TAG"
    fi
    log_panel_add info "Starting installation from $REPO..."
    do_install "$SELECTED_RELEASE_TAG" && true || log_panel_add err "Installation failed -- check output above"
    local W; W=$(term_width)
    local H; H=$(term_height)
    cursor_move $(( H - 1 )) 3
    printf '%s  Done! Press any key to return...%s' "$C_BRIGHT_GREEN" "$S_RESET"
    cursor_show
    read_key
    cursor_hide
    show_banner
}

tui_custom_install() {
    draw_subscreen "  ##   CUSTOM INSTALLATION"
    local W; W=$(term_width)
    local H; H=$(term_height)
    local max_len=$(( W - 14 ))

    # Repo prompt
    cursor_move 5 3
    printf '%s  Repository%s (user/repo, blank for current, "default" to reset)' "$S_BOLD" "$S_RESET"
    cursor_move 6 3
    printf '%s+%s%s%s+%s' "$C_BRIGHT_BLACK" "$(printf '%*s' $(( W - 8 )) '' | tr ' ' "$h")" "" "" "$S_RESET"
    cursor_move 7 3
    printf '%s| %s' "$C_BRIGHT_BLACK" "$S_RESET"
    local display_repo="$REPO"
    [ "${#display_repo}" -gt "$max_len" ] && display_repo="${display_repo:0:$((max_len - 3))}..."
    printf '%s%s%s' "$S_DIM" "$display_repo" "$S_RESET"
    cursor_move 7 $(( W - 4 ))
    printf ' %s|%s' "$C_BRIGHT_BLACK" "$S_RESET"
    cursor_move 8 3
    printf '%s+%s%s+%s' "$C_BRIGHT_BLACK" "$(printf '%*s' $(( W - 8 )) '' | tr ' ' "$h")" "" "$S_RESET"

    cursor_move 7 5
    cursor_show; stty echo
    read -r CUSTOM_REPO || true
    stty -echo 2>/dev/null || true; cursor_hide
    if [ "$CUSTOM_REPO" = "default" ] || [ "$CUSTOM_REPO" = "reset" ]; then
        REPO="$DEFAULT_REPO"
    elif [ -n "$CUSTOM_REPO" ]; then
        REPO="$CUSTOM_REPO"
    fi

    # Icon prompt
    cursor_move 10 3
    printf '%s  Icon URL or path%s (blank for current, "default" to reset)' "$S_BOLD" "$S_RESET"
    cursor_move 11 3
    printf '%s+%s%s+%s' "$C_BRIGHT_BLACK" "$(printf '%*s' $(( W - 8 )) '' | tr ' ' "$h")" "" "" "$S_RESET"
    cursor_move 12 3
    printf '%s| %s' "$C_BRIGHT_BLACK" "$S_RESET"
    local display_icon="$ICON_INPUT"
    [ "${#display_icon}" -gt "$max_len" ] && display_icon="${display_icon:0:$((max_len - 3))}..."
    printf '%s%s%s' "$S_DIM" "$display_icon" "$S_RESET"
    cursor_move 12 $(( W - 4 ))
    printf ' %s|%s' "$C_BRIGHT_BLACK" "$S_RESET"
    cursor_move 13 3
    printf '%s+%s%s+%s' "$C_BRIGHT_BLACK" "$(printf '%*s' $(( W - 8 )) '' | tr ' ' "$h")" "" "$S_RESET"

    cursor_move 12 5
    cursor_show; stty echo
    read -r CUSTOM_ICON || true
    stty -echo 2>/dev/null || true; cursor_hide
    if [ "$CUSTOM_ICON" = "default" ] || [ "$CUSTOM_ICON" = "reset" ]; then
        ICON_INPUT="$DEFAULT_ICON_URL"
    elif [ -n "$CUSTOM_ICON" ]; then
        ICON_INPUT="$CUSTOM_ICON"
    fi

    if ! tui_select_release "$REPO"; then
        show_banner
        return
    fi
    draw_subscreen "  ##   CUSTOM INSTALLATION"
    log_panel_init
    log_panel_add info "Repository : $REPO"
    log_panel_add info "Icon       : $ICON_INPUT"
    if [ "$SELECTED_RELEASE_TAG" != "latest" ] && [ -n "$SELECTED_RELEASE_TAG" ]; then
        log_panel_add info "Release    : $SELECTED_RELEASE_TAG"
    else
        log_panel_add info "Release    : Latest"
    fi
    log_panel_add step "Starting custom installation..."
    do_install "$SELECTED_RELEASE_TAG" && true || log_panel_add err "Installation failed"
    cursor_move $(( H - 1 )) 3
    printf '%s  Done! Press any key to return...%s' "$C_BRIGHT_GREEN" "$S_RESET"
    cursor_show; read_key; cursor_hide
    show_banner
}

tui_status() {
    draw_subscreen "  ??  SYSTEM STATUS"
    local W; W=$(term_width)
    local H; H=$(term_height)
    local col=3
    local row=5
    local cell_w=$(( (W - 8) / 2 ))

    # Panel 1: Application
    draw_thin_box "$row" "$col" "$cell_w" 8 "$C_BRIGHT_MAGENTA"
    cursor_move "$row" $(( col + 2 ))
    printf '%s%s  APPLICATION%s' "$S_BOLD" "$C_BRIGHT_MAGENTA" "$S_RESET"

    local app_status icon_status
    if [ -f "$BIN_DIR/$EXE_NAME" ]; then
        app_status="${C_BRIGHT_GREEN}Installed${S_RESET}"
    else
        app_status="${C_BRIGHT_RED}Not installed${S_RESET}"
    fi
    if [ -f "${ICON_DIR:-/dev/null}/shonenx.png" ]; then
        icon_status="${C_BRIGHT_GREEN}Present${S_RESET}"
    else
        icon_status="${C_BRIGHT_BLACK}Absent${S_RESET}"
    fi

    cursor_move $(( row + 2 )) $(( col + 2 ))
    printf '%s Status   : %s' "$S_DIM" "$S_RESET"
    printf '%b' "$app_status"

    cursor_move $(( row + 3 )) $(( col + 2 ))
    printf '%s Binary   : %s%s%s' "$S_DIM" "$C_BRIGHT_CYAN" "$BIN_DIR/$EXE_NAME" "$S_RESET"

    cursor_move $(( row + 4 )) $(( col + 2 ))
    printf '%s InstDir  : %s%s%s' "$S_DIM" "$C_BRIGHT_CYAN" "$INSTALL_DIR" "$S_RESET"

    cursor_move $(( row + 5 )) $(( col + 2 ))
    printf '%s Desktop  : %s' "$S_DIM" "$S_RESET"
    printf '%b' "$icon_status"

    cursor_move $(( row + 6 )) $(( col + 2 ))
    local repo_disp="$REPO"
    [ "${#repo_disp}" -gt $(( cell_w - 14 )) ] && repo_disp="${repo_disp:0:$(( cell_w - 17 ))}..."
    printf '%s Repo     : %s%s%s' "$S_DIM" "$C_BRIGHT_CYAN" "$repo_disp" "$S_RESET"

    # Panel 2: Shell Integration
    local col2=$(( col + cell_w + 2 ))
    draw_thin_box "$row" "$col2" "$cell_w" 8 "$C_BRIGHT_CYAN"
    cursor_move "$row" $(( col2 + 2 ))
    printf '%s%s  SHELL INTEGRATION%s' "$S_BOLD" "$C_BRIGHT_CYAN" "$S_RESET"

    _shell_status() {
        local lbl="$1" check="$2" r="$3"
        cursor_move "$r" $(( col2 + 2 ))
        local ok_icon="${C_BRIGHT_GREEN}*${S_RESET}"
        local no_icon="${C_BRIGHT_BLACK}o${S_RESET}"
        local st
        if eval "$check"; then st="$ok_icon Active"; else st="$no_icon Inactive"; fi
        printf '%s %-8s: %b' "$S_DIM" "$lbl" "$st"
    }

    _shell_status "Binary"   "[ -f \"$BIN_DIR/shonenx-manager\" ]"                                            $(( row + 2 ))
    _shell_status "Bash"     "[ -f \"$HOME/.bashrc\" ] && grep -q 'ShonenX Manager' \"$HOME/.bashrc\" 2>/dev/null" $(( row + 3 ))
    _shell_status "Zsh"      "[ -f \"$HOME/.zshrc\"  ] && grep -q 'ShonenX Manager' \"$HOME/.zshrc\"  2>/dev/null" $(( row + 4 ))
    _shell_status "Fish"     "[ -f \"$HOME/.config/fish/functions/shonenx-manager.fish\" ]"                    $(( row + 5 ))

    # Panel 3: PATH
    local row2=$(( row + 9 ))
    draw_thin_box "$row2" "$col" $(( W - 6 )) 5 "$C_BRIGHT_YELLOW"
    cursor_move "$row2" $(( col + 2 ))
    printf '%s%s  ENVIRONMENT%s' "$S_BOLD" "$C_BRIGHT_YELLOW" "$S_RESET"

    cursor_move $(( row2 + 2 )) $(( col + 2 ))
    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        printf '%s PATH     : %s%s in PATH [ok]%s' "$S_DIM" "$C_BRIGHT_GREEN" "$BIN_DIR" "$S_RESET"
    else
        printf '%s PATH     : %s%s NOT in PATH [!!]%s' "$S_DIM" "$C_BRIGHT_RED" "$BIN_DIR" "$S_RESET"
    fi

    cursor_move $(( row2 + 3 )) $(( col + 2 ))
    local mpv_stat
    command -v mpv >/dev/null 2>&1 && mpv_stat="${C_BRIGHT_GREEN}Found${S_RESET}" || mpv_stat="${C_BRIGHT_RED}Not found${S_RESET}"
    printf '%s mpv      : %b' "$S_DIM" "$mpv_stat"

    cursor_move $(( H - 1 )) 3
    printf '%s  Press any key to return...%s' "$S_DIM" "$S_RESET"
    cursor_show; read_key; cursor_hide
    show_banner
}

tui_setup_manager_screen() {
    draw_subscreen "  **  SETUP SHELL COMMAND"
    log_panel_init
    log_panel_add info "Configuring shonenx-manager across all shells..."
    do_manager
    local H; H=$(term_height)
    cursor_move $(( H - 1 )) 3
    printf '%s  Done! Press any key to return...%s' "$C_BRIGHT_GREEN" "$S_RESET"
    cursor_show; read_key; cursor_hide
    show_banner
}

tui_uninstall() {
    draw_subscreen "  xx   UNINSTALL SHONENX"
    local W; W=$(term_width)
    local H; H=$(term_height)

    cursor_move 5 3
    printf '%s  [!!]  This will remove ShonenX completely from your system.%s' "$C_BRIGHT_RED$S_BOLD" "$S_RESET"
    cursor_move 7 3
    printf '%s  Type %sYES%s to confirm, or press Enter to cancel: %s' "$C_WHITE" "$S_BOLD" "$S_RESET$C_WHITE" "$S_RESET"

    cursor_show; stty echo
    read -r CONFIRM || true
    stty -echo 2>/dev/null || true; cursor_hide

    if [ "$CONFIRM" = "YES" ]; then
        draw_subscreen "  xx   UNINSTALL SHONENX"
        log_panel_init
        do_uninstall
        cursor_move $(( H - 1 )) 3
        printf '%s  Uninstalled. Press any key to return...%s' "$C_BRIGHT_GREEN" "$S_RESET"
    else
        cursor_move 9 3
        printf '%s  Aborted. Press any key to return...%s' "$C_BRIGHT_YELLOW" "$S_RESET"
    fi
    cursor_show; read_key; cursor_hide
    show_banner
}

tui_exit() {
    clear_screen
    cursor_show
    stty echo 2>/dev/null || true
    printf '%s\n  Goodbye! *  See you next episode.\n\n%s' "$C_BRIGHT_MAGENTA" "$S_RESET"
    exit 0
}

# --- CLI Argument Parsing ----------------------------------
if [ $# -gt 0 ]; then
    ACTION=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install)     ACTION="install";   shift ;;
            --repo)        REPO="$2";          shift 2 ;;
            --icon)        ICON_INPUT="$2";    shift 2 ;;
            --tag|--release) SELECTED_RELEASE_TAG="$2"; shift 2 ;;
            --manager)     ACTION="manager";   shift ;;
            --uninstall)   ACTION="uninstall"; shift ;;
            --status)      ACTION="status";    shift ;;
            --help|-h)
                printf '\nUsage: %s [OPTIONS]\n\n' "$0"
                printf '  --install           Quick install\n'
                printf '  --repo <user/repo>  Custom repository\n'
                printf '  --icon <path|url>   Custom icon\n'
                printf '  --tag, --release    Specify release tag (e.g. v1.9.0-beta)\n'
                printf '  --manager           Setup shonenx-manager\n'
                printf '  --uninstall         Remove ShonenX\n'
                printf '  --status            Check install status\n'
                printf '  --help, -h          This help\n\n'
                exit 0 ;;
            *) printf 'Unknown option: %s\n' "$1"; exit 1 ;;
        esac
    done
    # Non-interactive mode -- plain output
    case "$ACTION" in
        install)
            LOG_LINES=()
            do_install "$SELECTED_RELEASE_TAG"
            ;;
        manager)
            LOG_LINES=()
            do_manager
            ;;
        uninstall)
            LOG_LINES=()
            do_uninstall
            ;;
        status)
            printf '\n  %sShonenX Status%s\n\n' "$S_BOLD" "$S_RESET"
            [ -f "$BIN_DIR/$EXE_NAME" ] && \
                printf '  %s[ok]%s  Application : Installed (%s)\n' "$C_BRIGHT_GREEN" "$S_RESET" "$BIN_DIR/$EXE_NAME" || \
                printf '  %s[!!]%s  Application : Not installed\n' "$C_BRIGHT_RED" "$S_RESET"
            printf '\n'
            ;;
        *)
            if [ "$REPO" != "$DEFAULT_REPO" ] || [ "$ICON_INPUT" != "$DEFAULT_ICON_URL" ] || [ -n "$SELECTED_RELEASE_TAG" ]; then
                LOG_LINES=(); do_install "$SELECTED_RELEASE_TAG"
            else
                printf 'No action specified. Use --help.\n'
            fi
            ;;
    esac
    exit 0
fi

# --- Launch TUI --------------------------------------------
stty -echo 2>/dev/null || true
run_menu