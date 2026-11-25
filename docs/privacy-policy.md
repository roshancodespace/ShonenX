# Privacy Policy

**Effective Date:** November 26, 2026  
**Last Updated:** November 26, 2026

ShonenX ("the Application", "we", "our") is an open-source, ad-free anime and manga client maintained by Roshan Kumar and community contributors (`https://github.com/roshancodespace/ShonenX`). We are committed to protecting your privacy and being transparent about how the Application handles data.

---

## 1. Summary

- **No Ads or Behavioral Tracking:** ShonenX contains no advertisements, ad networks, or third-party behavioral tracking SDKs.
- **No Developer Telemetry Server:** ShonenX does not collect, store, or sell personal data, usage analytics, or crash telemetry to the developer.
- **Local-First Architecture:** Your watch/read history, library, preferences, and authentication tokens are stored locally on your device.
- **Direct Third-Party Connections:** When you choose to connect external tracking accounts (such as **Trakt**, **AniList**, **MyAnimeList**, **Kitsu**, or **Simkl**) or use optional metadata/extension features, the Application communicates directly from your device to those services.

---

## 2. Information Stored Locally on Your Device

ShonenX stores the following information strictly on your device to provide core functionality:

- **Library & Progress Data:** Bookmarked titles, local watch/read status, episode/chapter progress, and playback history (stored in the local Isar database and `SharedPreferences`).
- **Application Preferences:** Theme settings, UI layout options, player/reader settings, subtitle styling, and custom configuration overrides.
- **Authentication Tokens & Credentials:** If you connect a third-party tracker account or supply custom API client credentials, your OAuth access tokens, refresh tokens, and credentials are stored locally using platform-backed secure storage (`flutter_secure_storage`, such as Android Keystore, Apple Keychain, Windows Credential Manager, or Linux `libsecret`).
- **Cached Media & Downloads:** Cover images, episode thumbnails, and user-initiated offline downloads are cached in your device's application storage.

None of this locally stored data is transmitted to the ShonenX developer.

---

## 3. Third-Party Tracking Services (Trakt, AniList, MyAnimeList, Kitsu, Simkl)

ShonenX allows you to optionally link external tracking accounts—including **Trakt**, **AniList**, **MyAnimeList**, **Kitsu**, and **Simkl**—to synchronize your anime/manga lists and playback progress.

### 3.1 How Authentication Works
- Authentication uses the respective provider's official **OAuth 2.0** flow (via your system browser or an embedded WebView, depending on your settings).
- ShonenX **does not** route your login credentials or OAuth tokens through a developer-operated backend server. Tokens are exchanged directly between your device and the provider's official API.

### 3.2 Data Accessed & Synchronized
When you authorize a tracking service (such as **Trakt**), ShonenX accesses and updates only the data required to provide list synchronization:
- **Profile Information:** Username, user ID, and avatar/banner URLs for display in the Application.
- **Library & Watchlist Data:** Your tracked shows, movies, anime, or manga, list statuses (e.g., Watching, Completed, Plan to Watch), scores/ratings, and episode/chapter progress.
- **Sync Actions:** Updating progress, scrobbling/marking episodes or chapters as watched/read, and updating list entries when triggered by you or your configured auto-sync threshold.

### 3.3 Provider Policies
Your use of any third-party tracking service is also governed by that service's own Privacy Policy and Terms of Service:
- **Trakt:** [https://trakt.tv/privacy](https://trakt.tv/privacy)
- **AniList:** [https://anilist.co/terms](https://anilist.co/terms)
- **MyAnimeList:** [https://myanimelist.net/about/privacy_policy](https://myanimelist.net/about/privacy_policy)
- **Kitsu:** [https://kitsu.io/privacy](https://kitsu.io/privacy)
- **Simkl:** [https://simkl.com/privacy/](https://simkl.com/privacy/)

---

## 4. Other Optional Network Services

Depending on which features you enable or use, ShonenX may make direct network requests from your device to the following services:

- **Metadata & Skip Timestamps:** Requests to public metadata providers and skip-segment services (such as AniSkip) using media titles or public media IDs to retrieve episode details, artwork, and intro/outro timestamps.
- **Comments (`Commentum`):** If you view or post comments, requests are sent directly to the configured comment service endpoint.
- **Discord Rich Presence:** On desktop platforms, if enabled, ShonenX communicates locally with your running Discord client via IPC/RPC to display what you are currently watching or reading.
- **Update Checks:** ShonenX may query GitHub Releases (`github.com/roshancodespace/ShonenX`) to check whether a newer version of the Application is available.
- **User-Installed Sources & Extensions:** ShonenX does not host or distribute media content. When you use built-in or user-installed extensions to search or stream media, requests are sent directly from your device to those external third-party sources, each governed by its own privacy practices.

---

## 5. Data Sharing & Disclosure

We do **not** sell, rent, trade, or otherwise transfer your personal information to third parties. Data leaves your device only when:
1. You explicitly authenticate with or sync to a third-party tracker (e.g., Trakt, AniList, MyAnimeList, Kitsu, Simkl).
2. You use an optional network feature (such as metadata lookup, comments, update checks, or content extensions).

---

## 6. Data Retention & Your Rights (Deletion & Revocation)

Because your data is stored locally on your device and synced only with accounts you control, you have full control over retention and deletion:

- **Disconnect a Tracker:** Go to **Settings → Tracking** inside ShonenX to log out or switch accounts. Logging out removes the stored OAuth tokens from your device's secure storage.
- **Revoke OAuth Access:** You can revoke ShonenX's access at any time from your connected provider's account settings (for example, **Connected Apps** in your Trakt, AniList, MyAnimeList, Kitsu, or Simkl account settings).
- **Delete Local Data:** You can clear cached media, delete watch/read history, or uninstall ShonenX to permanently remove all locally stored databases and preferences from your device.

---

## 7. Security

We use platform-provided secure storage (`flutter_secure_storage`) for sensitive credentials and OAuth tokens, and communicate with supported APIs over HTTPS/TLS. However, no method of electronic storage or transmission is 100% secure, and you are responsible for keeping your device and third-party accounts secure.

---

## 8. Children's Privacy

ShonenX is not directed to children under the age of 13 (or the minimum age required by applicable law in your jurisdiction, or the minimum age required by third-party tracking providers you choose to connect). We do not knowingly collect personal information from children.

---

## 9. Changes to This Privacy Policy

We may update this Privacy Policy from time to time to reflect changes in the Application or legal/API requirements. Any updates will be posted in this document with an updated "Last Updated" date.

---

## 10. Contact

If you have any questions, privacy concerns, or requests regarding this Privacy Policy or ShonenX, you can reach the maintainer through:

- **GitHub Repository & Issues:** [https://github.com/roshancodespace/ShonenX/issues](https://github.com/roshancodespace/ShonenX/issues)
- **Community Discord:** [https://discord.gg/uJyXZYSmH4](https://discord.gg/uJyXZYSmH4)

