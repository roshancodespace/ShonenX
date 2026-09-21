# Local Setup & Installation

This guide walks you through setting up ShonenX for local development. Whether you are a beginner looking to compile the app yourself or a seasoned contributor, this page covers the prerequisites.

## Prerequisites

ShonenX relies on a native C++ runner and specific Rust networking bindings. You must have the following installed to start building:

1.  **Flutter SDK**
    *   **Channel:** Stable
    *   **Version:** `3.41.x` (Highly recommended to use the latest stable release, such as `3.41.9`).
2.  **Rust**
    *   Install via `rustup`. This is strictly required for the `rhttp` and `libtorrent` dependencies to compile their FFI bindings locally.
3.  **CMake & Ninja** 
    *   Required for native C++ desktop builds on Windows and Linux.
4.  **Android Studio / NDK** 
    *   Required for Android builds. Make sure you have the NDK installed via the SDK Manager.

## Building the Repository

1. **Clone the repository:**
   ```bash
   git clone https://github.com/roshancodespace/shonenx.git
   cd shonenx
   ```

2. **Fetch dependencies:**
   ShonenX uses a script to fetch dependencies for the main app and all local packages (like the bridge).
   ```bash
   flutter pub get
   ```

3. **Generate Isar models and Riverpod code:**
   Because ShonenX uses code generation for its local database (Isar) and state management (Riverpod), you **must** run the build runner before your first build, and anytime you change a model.
   ```bash
   dart run build_runner build -d
   ```

4. **Run the application:**
   Launch the app on your preferred platform:
   ```bash
   flutter run -d linux # or windows, or an android emulator
   ```

## Common Build Issues

- **Rust compilation errors:** Ensure your Rust toolchain is up to date (`rustup update`). The `rhttp` package compiles Rust bindings natively during the build phase. If it fails, check that your system's C compiler is accessible.
- **Linux GTK errors:** You may need to install `libgtk-3-dev` and `libmpv-dev` via your package manager (e.g., `sudo apt install libgtk-3-dev libmpv-dev`).
- **Isar schema mismatches:** If the app crashes on startup regarding database schemas, wipe the local application data directory (usually `~/.local/share/shonenx` on Linux) and re-run.
