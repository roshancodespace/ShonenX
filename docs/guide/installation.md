# Installation Guide

ShonenX is available across multiple platforms. Follow the instructions below for your specific device to get started.

> [!WARNING] Disclaimer
> ShonenX is a tool that aggregates content from third-party sources. We do not host, store, or distribute any copyrighted content. The developers are not responsible for the content provided by third-party extensions. Users are solely responsible for the extensions they install and the content they access.

## Android

We provide multiple APK architectures:
*   **ARM64:** For most modern devices.
*   **ARM7:** For older devices (Android 9 or below).

Download the appropriate `.apk` from our release page and follow the standard Android installation process.

## Windows

> [!CAUTION] WebView2 Required
> You **must** have the [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) installed on your system before running ShonenX. Without it, the application will crash during login flows.

*   **Installer:** Download the `.exe` installer, run it, and follow the on-screen wizard.
*   **Portable:** Download the `.zip` archive, extract it to your preferred location, and run `ShonenX.exe` directly.

## Linux

For Linux users, we provide an automated bash installation script. 

Open your terminal and run:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roshancodespace/ShonenX/main/install.sh)"
```
> [!NOTE] Dependency Check
> Ensure you have `libmpv` installed on your system via your package manager, as it is required for the native video player.

## macOS & iOS

> [!WARNING] Highly Experimental
> The iOS and macOS builds are currently **highly experimental** and may be unstable.

*   **iOS:** Download the `.ipa` file. You must sideload it using tools like AltStore, Sideloadly, or LiveContainer.
*   **macOS:** Download the `.dmg` file, open it, and drag ShonenX into your Applications folder.
