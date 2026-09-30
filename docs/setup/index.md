# Local Setup & Build Guide

Building ShonenX requires a few extra native dependencies beyond a standard Flutter app. 

Because we link **Rust FFI bindings** (`rhttp` and `libtorrent`), compile native **C++ platform runners**, use an embedded **`mpv` video core**, and run **WebKit** for desktop OAuth logins, you need the proper system toolchains installed before building. 

This guide walks you through setting up your environment so you can compile smoothly without running into cryptic CMake or linker errors.

---

## Prerequisites

### 1. Flutter SDK (Channel: Stable)
*   **Version:** `3.41.x` (or newer stable).
*   Run `flutter doctor` to ensure your Flutter environment and Android/desktop toolchains are recognized.

### 2. Rust Toolchain (Strictly Required)
We use `rhttp` (Rust-powered HTTP client) and `libtorrent_flutter` to avoid TLS fingerprint blocks and handle torrent streaming. These packages compile native Rust code during the build process.
*   Install via official `rustup`:
    ```bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```
*   Ensure `cargo` and `rustc` are available in your `$PATH`.

### 3. CMake & Ninja
Desktop builds compile native C++ runners. 
*   **Windows:** Install the "Desktop development with C++" workload via the Visual Studio Installer.
*   **Linux:** Install `cmake` and `ninja-build` via your package manager.

### 4. Linux Native Dependencies (For Linux Desktop Builds)
Building on Linux requires development headers for GTK, media playback (`mpv`), and an in-app webview (`WPE WebKit`):

> [!NOTE] Why is WPE WebKit required on Linux?
> Android and Windows have built-in system webviews for OAuth authentication flows (like logging into AniList or MyAnimeList). Linux desktop environments do not provide a standard built-in webview widget. We use `flutter_inappwebview_linux`, which relies on `libwpewebkit`. Without it, CMake will fail with `WPE WebKit not found`.

Install the packages for your distro:

::: code-group

```bash [Ubuntu / Debian]
sudo apt update
sudo apt install -y \
  build-essential \
  cmake \
  ninja-build \
  libgtk-3-dev \
  libmpv-dev \
  libwpewebkit-1.0-dev
```

```bash [Arch Linux]
sudo pacman -Syu --needed \
  base-devel \
  cmake \
  ninja \
  gtk3 \
  mpv \
  wpewebkit
```

```bash [Fedora]
sudo dnf install -y \
  cmake \
  ninja-build \
  gtk3-devel \
  mpv-libs-devel \
  wpewebkit-devel
```

:::

---

## Step-by-Step Build Instructions

### Step 1: Clone the Repository
```bash
git clone https://github.com/roshancodespace/shonenx.git
cd shonenx
```

### Step 2: Fetch Dependencies
ShonenX includes local packages (like `anymex_extension_bridge`). Fetch all dependencies:
```bash
flutter pub get
```

### Step 3: Run the Build Runner (Crucial)
Because we use **Isar** (local database) and **Riverpod** (code-generated providers), the generated `.g.dart` files must be present before the app can compile:

```bash
dart run build_runner build -d
```
*(The `-d` flag deletes conflicting generated outputs so it doesn't fail on preexisting files).*

### Step 4: Run the Application
Launch on your target device or desktop platform:

```bash
# Run on Linux desktop
flutter run -d linux

# Run on Windows desktop
flutter run -d windows

# Run on Android (emulator or connected device)
flutter run -d android
```

---

## Troubleshooting Common Build Issues

### 1. `CMake Error: WPE WebKit not found`
*   **Cause:** Missing `libwpewebkit-1.0-dev` (Ubuntu) or `wpewebkit` (Arch).
*   **Fix:** Install the package using the commands above and wipe the build cache (`rm -rf build`) before rebuilding.

### 2. Rust Linker or `librhttp.so` Missing During Tests
*   **Cause:** Running headless unit tests with `flutter test` runs in a pure Dart VM environment that may not know where the compiled Rust dynamic library is located.
*   **Fix:** Build the desktop app once (`flutter build linux --debug`), then provide the library path to the dynamic linker:
    ```bash
    LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test
    ```

### 3. `IsarSchemaError: Type model mismatch`
*   **Cause:** An Isar model was changed or pulled from upstream, and the local database schema on disk is outdated.
*   **Fix:** Clear the local app data so Isar can recreate fresh tables:
    *   **Linux:** `rm -rf ~/.local/share/shonenx`
    *   **Windows:** `%APPDATA%\shonenx`
    *   **Android:** Clear app storage in Android App Settings.
