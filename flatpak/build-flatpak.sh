#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== ShonenX Flatpak Builder ==="

cd "$ROOT_DIR"

# Resolve Flutter & Dart commands (supports FVM if available)
FLUTTER_BIN="flutter"
DART_BIN="dart"
if ! command -v flutter >/dev/null 2>&1; then
    if command -v fvm >/dev/null 2>&1; then
        FLUTTER_BIN="fvm flutter"
        DART_BIN="fvm dart"
    elif [ -x "$HOME/fvm/default/bin/flutter" ]; then
        FLUTTER_BIN="$HOME/fvm/default/bin/flutter"
        DART_BIN="$HOME/fvm/default/bin/dart"
    fi
fi

BUNDLE_DIR="$ROOT_DIR/build/linux/x64/release/bundle"

FORCE_REBUILD=false
for arg in "$@"; do
    if [ "$arg" = "--rebuild" ] || [ "$arg" = "-f" ]; then
        FORCE_REBUILD=true
    fi
done

if [ "$FORCE_REBUILD" = true ] || [ ! -d "$BUNDLE_DIR" ] || [ ! -f "$BUNDLE_DIR/shonenx" ]; then
    echo ">> Building Linux release bundle with Flutter ($FLUTTER_BIN)..."
    if [ ! -f "keys.json" ]; then
        echo ">> Generating temporary keys.json for build..."
        cat > keys.json <<EOF
{
  "ANILIST_CLIENT_ID": "",
  "ANILIST_CLIENT_SECRET": "",
  "MAL_CLIENT_ID": "",
  "MAL_CLIENT_SECRET": "",
  "SIMKL_CLIENT_ID": "",
  "SIMKL_CLIENT_SECRET": "",
  "COMMENTUM_API_URL": "",
  "RELEASE_REPO": "roshancodespace/ShonenX"
}
EOF
    fi
    $FLUTTER_BIN config --enable-linux-desktop
    $FLUTTER_BIN pub get
    $DART_BIN run build_runner build -d
    $FLUTTER_BIN build linux --release --dart-define-from-file=keys.json
fi

echo ">> Preparing clean Flatpak source bundle directory..."
rm -rf "$SCRIPT_DIR/bundle"
mkdir -p "$SCRIPT_DIR/bundle"
cp -r "$BUNDLE_DIR"/* "$SCRIPT_DIR/bundle/"

if ! command -v flatpak-builder >/dev/null 2>&1; then
    echo "Error: flatpak-builder is not installed."
    echo "Please install flatpak and flatpak-builder using your package manager."
    exit 1
fi

echo ">> Ensuring GNOME 47 Platform & SDK are installed..."
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
flatpak install --user -y flathub org.gnome.Platform//47 org.gnome.Sdk//47 || true

echo ">> Building Flatpak..."
cd "$ROOT_DIR"
flatpak-builder --user --install-deps-from=flathub --force-clean --disable-rofiles-fuse \
    --repo="$SCRIPT_DIR/repo" \
    "$SCRIPT_DIR/build-dir" \
    "$SCRIPT_DIR/com.roshancodespace.shonenx.yml"

OUTPUT_BUNDLE="$ROOT_DIR/ShonenX-linux-x86_64.flatpak"
echo ">> Creating single-file Flatpak bundle: $OUTPUT_BUNDLE..."
flatpak build-bundle "$SCRIPT_DIR/repo" "$OUTPUT_BUNDLE" com.roshancodespace.shonenx

echo "=== Flatpak built successfully: $OUTPUT_BUNDLE ==="
echo "Install with: flatpak install --user $OUTPUT_BUNDLE"
echo "Run with:     flatpak run com.roshancodespace.shonenx"
