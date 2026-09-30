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

For Linux users, we provide an automated shell installer that configures the executable and desktop launcher:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roshancodespace/ShonenX/main/install.sh)"
```

### Video Playback Dependency (`libmpv`)
Because ShonenX uses native `mpv` for hardware-accelerated video decoding and styled subtitles, ensure `libmpv` is installed:

*   **Ubuntu / Debian / Mint:** `sudo apt install libmpv-dev libmpv2`
*   **Arch / Manjaro / EndeavourOS:** `sudo pacman -S mpv`
*   **Fedora:** `sudo dnf install mpv-libs`

---

## Apple Platforms (macOS & iOS)

> [!NOTE] Sideloading Notice
> macOS and iOS builds are in active development.

*   **macOS:** Download the `.dmg`, open it, and move `ShonenX.app` to your Applications folder. If blocked by Gatekeeper ("unidentified developer"), allow the app in **System Settings → Privacy & Security**.
*   **iOS:** Download the `.ipa` file from GitHub Releases. Sideload using tools such as **AltStore**, **SideStore**, or **LiveContainer**.
