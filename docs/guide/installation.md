# Installation Guide

ShonenX is available across multiple desktop and mobile platforms. Choose the guide for your system below.

> [!WARNING] Legal Disclaimer
> ShonenX is an open-source media player and aggregator tool. We do not host, store, or distribute copyrighted video or manga content. Users are responsible for the third-party extension repositories they choose to install and the media they view.

---

## Android (Phones & Tablets)

Download the latest `.apk` from the [GitHub Releases](https://github.com/roshancodespace/shonenx/releases) page:

*   **`arm64-v8a` (Recommended):** For modern 64-bit devices.
*   **`armeabi-v7a`:** For older 32-bit devices (Android 9 and earlier).
*   **`universal`:** Compatible with all supported architectures.

---

## Windows Desktop (10 & 11)

Windows builds are available as an installer or portable archive:
*   **Installer (`.exe`):** Recommended for automatic shortcuts and desktop integration.
*   **Portable (`.zip`):** Extract and run `ShonenX.exe` directly from any folder.

> [!IMPORTANT] WebView2 Runtime Requirement
> ShonenX requires the **[Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)** to handle OAuth login flows (AniList, MyAnimeList). While pre-installed on most modern Windows 11 systems, if login dialogs fail to open, ensure WebView2 is installed.

---

## Linux Desktop

### Option 1: Flatpak (Recommended)

Flatpak packages ShonenX with all runtime dependencies (including hardware-accelerated `libmpv` and `WebKitGTK`) isolated inside an application sandbox. It runs uniformly across any distribution, including immutable systems like SteamOS (Steam Deck), Fedora Silverblue, and openSUSE MicroOS:

1. Download `ShonenX-linux-x86_64.flatpak` from the [GitHub Releases](https://github.com/roshancodespace/ShonenX/releases) page.
2. Install the bundle:
   ```bash
   flatpak install --user ShonenX-linux-x86_64.flatpak
   ```
3. Launch ShonenX:
   ```bash
   flatpak run com.roshancodespace.shonenx
   ```

### Option 2: Automated Install Script

For native installations, we provide an interactive shell script that fetches the latest release, sets up desktop shortcuts, registers URL scheme handlers, and configures your PATH:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roshancodespace/ShonenX/main/install.sh)"
```

> [!TIP] Native Video Playback Dependency (`libmpv`)
> When using the native shell installer or portable zip (outside of Flatpak), ensure `libmpv` is installed on your host:
> * **Ubuntu / Debian / Mint:** `sudo apt install libmpv-dev libmpv2`
> * **Arch / Manjaro / EndeavourOS:** `sudo pacman -S mpv`
> * **Fedora:** `sudo dnf install mpv-libs`

### Option 3: AppImage & Portable Zip

Download `ShonenX-linux-x86_64.AppImage` or `ShonenX-linux.zip` from [GitHub Releases](https://github.com/roshancodespace/ShonenX/releases). For AppImage, make it executable and run:

```bash
chmod +x ShonenX-linux-x86_64.AppImage
./ShonenX-linux-x86_64.AppImage
```

---

## Apple Platforms (macOS & iOS)

> [!NOTE] Sideloading Notice
> macOS and iOS builds are in active development.

*   **macOS:** Download the `.dmg`, open it, and move `ShonenX.app` to your Applications folder. If blocked by Gatekeeper ("unidentified developer"), allow the app in **System Settings → Privacy & Security**.
*   **iOS:** Download the `.ipa` file from GitHub Releases. Sideload using tools such as **AltStore**, **SideStore**, or **LiveContainer**.
