<div align="center">

   <img src="assets/icons/app_icon-modified-2.png" alt="ShonenX Logo" width="120"/>

# ShonenX

### A Modern AniList & MyAnimeList Client

[![Flutter](https://img.shields.io/badge/Flutter-≥3.8.1-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-≥3.8.1-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/Version-1.7.5-blue)](https://github.com/Darkx-dev/ShonenX/releases)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-orange.svg)](https://opensource.org/licenses/apache-2-0)
[![GitHub stars](https://img.shields.io/github/stars/Darkx-dev/ShonenX?style=social)](https://github.com/Darkx-dev/ShonenX/stargazers)
[![Discord](https://img.shields.io/discord/1348756894034165800?color=7289da&label=Discord&logo=discord&logoColor=white)](https://discord.gg/uJyXZYSmH4)

Track and manage your anime library with AniList and MyAnimeList integration. Built with Flutter for Android and Windows.

[Features](#-features) • [Screenshots](#-screenshots) • [Installation](#-installation) • [Contributing](#-contributing)

</div>

---

## ✨ Features

### 📊 Anime Tracking
- **AniList Integration** - Manage your anime library *(In Development)*
- **MyAnimeList Support** - MAL client features *(Early Development)*
- **Local Progress Tracking** - Continue watching without login
- **Watch History** - Track your viewing locally

### 🎨 Customization
- **Custom Design System** - Unique UI with smooth animations
- **Extensive Theming** - Wide range of theme options
- **Light/Dark Mode** - Comfortable viewing anytime
- **Advanced Settings** - Personalize your experience

### 🔌 Extensions
- **Mangayomi Extensions** - Anime-focused extension support *(Experimental)*
- **Built-in Sources** - Pre-configured providers
- **Jikan Sync** - Episode metadata *(Experimental)*

### 🔍 Search & Discovery
- **Advanced Search** - Comprehensive filtering
- **Content Filters** - Adult content toggle (off by default)
- **Continue Watching** - Resume where you left off

### 🌐 Platform Support
- **Android** - Fully supported mobile experience
- **Windows** - Native desktop build supported
- **Linux** - Experimental builds (via install script)
- **iOS/macOS** - Not planned currently

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
  <tr>
    <td align="center"><img src="screenshots/mobile/image1.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image2.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image3.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image4.jpg" width="200"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/mobile/image5.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image6.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image7.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image8.jpg" width="200"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/mobile/image9.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image10.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image11.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image12.jpg" width="200"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/mobile/image13.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image14.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image15.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image16.jpg" width="200"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/mobile/image17.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image18.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image19.jpg" width="200"/></td>
    <td align="center"><img src="screenshots/mobile/image20.jpg" width="200"/></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/mobile/image21.jpg" width="200"/></td>
    <td></td>
    <td></td>
    <td></td>
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

## 🛠️ Technology Stack

**Framework**: Flutter ≥3.8.1 | **Language**: Dart ≥3.8.1 | **Version**: 1.7.5

<details>
<summary><b>View Key Dependencies</b></summary>

```yaml
dependencies:
  flutter_riverpod: ^3.0.1
  go_router: ^14.7.1
  hive_ce: ^2.16.0
  hive_ce_flutter: ^2.1.0
  media_kit: ^1.2.6
  media_kit_video: ^2.0.1
  graphql: ^5.2.3
  google_fonts: ^6.2.1
  cached_network_image: ^3.4.1
  isar_community: ^3.3.0
  dio: ^5.9.0
  flex_color_scheme: ^8.4.0
  dynamic_color: 1.7.0
```

</details>

---

## 🚀 Installation

### 📱 Android
Download the latest `.apk` from the [Releases](https://github.com/Darkx-dev/ShonenX/releases) page.

### 🪟 Windows
Download the `Windows-Portable.zip` or the `.exe` installer from the [Releases](https://github.com/Darkx-dev/ShonenX/releases) page.

### 🐧 Linux
Run the following command to install/update:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Darkx-dev/ShonenX/main/install.sh)
```

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

## 🤝 Contributing

Contributions welcome! Fork the repo, create a feature branch, and submit a PR.

---

## 📄 License

Apache 2.0 License - see [LICENSE](LICENSE) file.

---

## 📞 Support

**Developer**: Roshan Kumar  
**GitHub**: [@roshancodespace](https://github.com/roshancodespace)  
**Email**: roshan.codespace@gmail.com  
**Discord**: [Join Community](https://discord.gg/uJyXZYSmH4)

---

<div align="center">

### ⭐ Star this repo if you find it useful!

**Made with ❤️ by [Roshan Kumar](https://github.com/roshancodespace)**

</div>