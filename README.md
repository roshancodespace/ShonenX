<div align="center">

   <img src="https://raw.githubusercontent.com/roshancodespace/shonenx/main/assets/icons/app_icon-modified-2.png" alt="ShonenX Logo" width="120"/>

# ShonenX

### Read. Watch. Track.

[![Flutter](https://img.shields.io/badge/Flutter-≥3.8.1-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-≥3.8.1-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-1.7.5-blue)](https://github.com/roshancodespace/ShonenX/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GitHub stars](https://img.shields.io/github/stars/roshancodespace/ShonenX?style=social)](https://github.com/roshancodespace/ShonenX/stargazers)
[![Discord](https://img.shields.io/discord/1348756894034165800?color=7289da&label=Discord&logo=discord&logoColor=white)](https://discord.gg/uJyXZYSmH4)

**[🌐 Visit the Official Website](https://shonenx.vercel.app)**

Started as a fun personal project. Now an open-source anime and manga companion. No ads, no trackers, pure data sovereignty. Syncs cleanly with MAL and AniList.

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Extensions](#-extensions) • [Legal](#-legal--dmca-disclaimer)

</div>

---

## ☕ Supporters

<table>
  <tr>
    <td align="center">
        <img src="https://cdn.buymeacoffee.com/uploads/profile_pictures/default/v2/DEBBB9/IZ.png" width="80px;" />
        <br />
        <sub><b>Izan</b></sub>
    </td>
    <td align="center">
        <img src="https://cdn.buymeacoffee.com/uploads/profile_pictures/default/v2/E3CBF4/EK.png" width="80px;" />
        <br />
        <sub><b>EVEE KNOA</b></sub>
    </td>
  </tr>
</table>

---

## ✨ Features

- **Omni-Sync Tracking:** Native bidirectional integration with MyAnimeList and AniList.
- **Custom Reader & Player:** Low-latency media playback and reading with customizable flow controls and AMOLED dark mode support.
- **Offline Availability:** Complete volume and season downloading for offline viewing and reading.
- **External Extensions:** Utilizes the AnymeX Extension Runtime Bridge, enabling Aniyomi and Mangayomi extension support. The client ships bare-bones; all sources must be manually added by the user.
- **Cross-Platform:** High-performance native builds for Android, Windows, and Linux.

---

## 🛠️ Technology Stack

**Framework**: Flutter ≥3.8.1 | **Language**: Dart ≥3.8.1

<details>
<summary><b>View Key Dependencies</b></summary>

```yaml
dependencies:
  flutter_riverpod: ^3.0.1
  go_router: ^14.7.1
  media_kit: ^1.2.6
  media_kit_video: ^2.0.1
  graphql: ^5.2.3
  isar_community: ^3.3.0
  dio: ^5.9.0
  flex_color_scheme: ^8.4.0
```

</details>

---

## 📸 Screenshots

<details>
<summary><b>📱 Android Screenshots (Click to expand)</b></summary>

<br/>

<div align="center">
<table>
  <tr>
    <td align="center">
      <img src="screenshots/mobile/home.jpg" width="200" alt="Home"/>
      <br/><b>Home</b>
    </td>
    <td align="center">
      <img src="screenshots/mobile/details.jpg" width="200" alt="Details"/>
      <br/><b>Details</b>
    </td>
    <td align="center">
      <img src="screenshots/mobile/stream.jpg" width="200" alt="Player"/>
      <br/><b>Player</b>
    </td>
    <td align="center">
      <img src="screenshots/mobile/anilist.jpg" width="200" alt="AniList"/>
      <br/><b>AniList</b>
    </td>
  </tr>
</table>
</div>

</details>

<details>
<summary><b>🖥️ Desktop Views (Windows/Linux)</b></summary>

<br/>

<div align="center">
<table>
  <tr>
    <td align="center">
      <img src="screenshots/desktop/home.jpg" width="400" alt="Desktop Home"/>
      <br/><b>Home Screen</b>
    </td>
    <td align="center">
      <img src="screenshots/desktop/details.jpg" width="400" alt="Desktop Details"/>
      <br/><b>Anime Details</b>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="screenshots/desktop/stream.jpg" width="400" alt="Desktop Player"/>
      <br/><b>Video Player</b>
    </td>
    <td align="center">
      <img src="screenshots/desktop/anilist.jpg" width="400" alt="Desktop AniList"/>
      <br/><b>AniList Integration</b>
    </td>
  </tr>
</table>
</div>

</details>

---

## 🚀 Installation

### 📱 Android
Download the latest `.apk` from the [GitHub Releases](https://github.com/roshancodespace/ShonenX/releases) page.

### 🪟 Windows
Download the `Windows-Portable.zip` or the `.exe` installer from the [Releases](https://github.com/roshancodespace/ShonenX/releases) page.

### 🐧 Linux (Universal Install Script)
We provide a universal interactive installation script for Linux users. It will fetch the latest release, extract it, set up the desktop icon, and add it to your PATH automatically.

Run the following command in your terminal:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roshancodespace/ShonenX/main/install.sh)"
```
*Note: You can run this same command again to uninstall ShonenX safely!*

### 🛠️ Build from Source
**Prerequisites**: Flutter SDK ≥3.8.1, Git
```bash
git clone https://github.com/roshancodespace/ShonenX.git
cd ShonenX
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run # Select your device/platform
```

---

## ⚖️ Legal & DMCA Disclaimer

Please read this before complaining.

**01. Service Nature**  
Look, ShonenX does not host, upload, or own any of the media you see in the app. It's literally just a frontend client. It's a glorified web browser that makes stuff look pretty. We don't have servers full of anime.

**02. APIs & Metadata**  
The covers, synopses, and schedules you see? That's all pulled directly from public APIs like AniList and MyAnimeList. ShonenX just displays what they send back. Don't sue us for showing a picture of Goku.

**03. User Extensions & Content**  
Any "extensions" or third-party sources you decide to install are entirely on you. ShonenX doesn't distribute copyrighted material or endorse piracy. If you put in a weird URL and watch something you shouldn't, that's your problem, not ours. Make sure you follow your local laws, we are not your lawyers.

If you're a copyright holder looking to DMCA someone, you're barking up the wrong tree. Go find the extension developers or whoever is actually hosting the video files.

---

## 🤝 Contributing & Documentation

Contributions are welcome! Feel free to inspect the code, compile from source, open an issue, or contribute if you understand the architecture.

---

## 📞 Support

**Developer**: Roshan Kumar Sharma  
**GitHub**: [@roshancodespace](https://github.com/roshancodespace)  
**Email**: roshan.codespace@gmail.com  
**Discord**: [Join Community](https://discord.gg/uJyXZYSmH4)  
**License**: GPL-3.0 (See [LICENSE](LICENSE) file)

---

<div align="center">

### ⭐ Star this repo if you find it useful!

**Made with ❤️ by [Roshan Kumar](https://github.com/roshancodespace)**

</div>
