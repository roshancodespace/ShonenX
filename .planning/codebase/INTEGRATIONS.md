---
last_mapped_commit: 184e63f99949cf25990cd41afc1bbdaf15a3cf70
last_mapped_at: 2026-11-07
---
# External Integrations

**Analysis Date:** 2026-11-07

## APIs & External Services

**Anime & Manga Tracking Services:**
- AniList - Media discovery, search, anime/manga progress tracking, user lists, airing schedule
  - SDK/Client: Direct GraphQL HTTP client via `rhttp` / `http` (`lib/features/tracking/engine/trackers/anilist/anilist_tracker.dart`)
  - Auth: OAuth2 Bearer token configured via `ANILIST_CLIENT_ID` and `ANILIST_CLIENT_SECRET` in `lib/core/utils/env.dart`
- MyAnimeList (MAL) - Anime/manga list sync, search, and progress tracking
  - SDK/Client: REST API client (`lib/features/tracking/engine/trackers/mal/mal_tracker.dart`)
  - Auth: OAuth2 with PKCE (Proof Key for Code Exchange) configured via `MAL_CLIENT_ID` and `MAL_CLIENT_SECRET` in `lib/core/utils/env.dart`
- Simkl - Watchlist synchronization and episode scrobbling
  - SDK/Client: REST API client (`lib/features/tracking/engine/trackers/simkl/simkl_tracker.dart`)
  - Auth: OAuth2 configured via `SIMKL_CLIENT_ID` and `SIMKL_CLIENT_SECRET` in `lib/core/utils/env.dart`
- Kitsu - Media tracking and calendar information
  - SDK/Client: REST API client (`lib/features/tracking/engine/trackers/kitsu/kitsu_tracker.dart`)
  - Auth: Resource owner password credentials / user token

**Video & Episode Metadata Services:**
- AniSkip - Intro/outro skip timestamps for video playback
  - SDK/Client: REST client in `lib/features/player/data/aniskip_service.dart` querying `api.aniskip.com`
  - Auth: Public API (no credentials required)
- AniZip - Media ID mapping between AniList, MyAnimeList, Kitsu, AniDB
  - SDK/Client: HTTP client in `lib/features/episode_metadata/services/anizip_metadata_client.dart`
  - Auth: Public API
- Jikan - Unofficial MyAnimeList REST API fallback
  - SDK/Client: HTTP client in `lib/features/episode_metadata/services/jikan_metadata_client.dart`
  - Auth: Public API
- Tenrai - Episode titles and thumbnail metadata provider
  - SDK/Client: HTTP client in `lib/features/episode_metadata/services/tenrai_metadata_client.dart`
  - Auth: Public API

**Community & Social:**
- Commentum - Episode comments, discussions, and replies
  - SDK/Client: `packages/commentum_client` and `lib/features/comments/api/commentum_client.dart`
  - Auth: Configured via `COMMENTUM_API_URL` and internal auth tokens
- Discord - Rich Presence integration (showing currently watched anime/read manga) and OAuth login
  - SDK/Client: `flutter_discord_rpc_fork` and REST client in `lib/features/discord/services/discord_rpc_service.dart` and `lib/features/discord/services/discord_api_service.dart`
  - Auth: Discord Application ID `1277648352528765038` and OAuth2 Bearer token

**Remote Configuration & Updates:**
- GitHub Raw - Dynamic feature flags, announcements, and remote config
  - Endpoint: `https://raw.githubusercontent.com/roshancodespace/shonenx-config/refs/heads/main/remote_config.json` via `lib/core/remote_config/services/remote_config_service.dart`
  - Auth: Public
- GitHub Releases - In-app version check, release notes, and automated app updates
  - Endpoint: `https://api.github.com/repos/roshancodespace/shonenx/releases` via `lib/features/updates/services/update_service.dart`
  - Auth: Public

**Network & DNS Security:**
- DNS over HTTPS (DoH) - Cloudflare (`https://cloudflare-dns.com/dns-query`), Google (`https://dns.google/dns-query`), Quad9 (`https://dns.quad9.net/dns-query`)
  - SDK/Client: Custom DoH resolver in `lib/core/network/doh/doh_resolver.dart` with in-memory cache `lib/core/network/doh/doh_cache.dart`

## Data Storage

**Databases:**
- Isar Community 3.3.2 (Embedded NoSQL)
  - Database file: `shonenx_db.isar` located in app documents directory (`lib/app_init.dart`)
  - Schemas: `CacheEntrySchema`, `LibraryEntrySchema`, `MediaPreferenceSchema`, `IsarTrackerLinkSchema`, `HistoryEntrySchema`, `DownloadTaskSchema`, `NotificationSubscriptionSchema`, `KvEntrySchema`
  - Client: `isar_community` Dart API

**File Storage:**
- Local filesystem only (`path_provider`):
  - Application documents directory: Database, offline backups (`lib/core/services/backup_service.dart`), custom subtitle files
  - Application cache directory: HTTP network cache, image cache (`cached_network_image`), video buffer temporary files
  - Download storage directory: Downloaded media files and HLS segments via `lib/features/downloads/providers/download_provider.dart` and `packages/byte_me`

**Caching:**
- Isar-backed Key-Value & Response Cache (`lib/core/caching/cache_manager.dart`) for API response caching with TTL
- SharedPreferences for user preferences and persistent UI flags (`lib/shared/providers/storage_provider.dart`)
- In-memory DNS cache in `lib/core/network/doh/doh_cache.dart`

## Authentication & Identity

**Auth Provider:**
- Multi-provider OAuth2 & Token Storage (`lib/features/tracking/engine/base_tracker.dart`):
  - OAuth2 via `flutter_web_auth_2` (`packages/flutter_web_auth`) capturing app link callbacks
  - Secure credential storage via `flutter_secure_storage` (`lib/core/network/secure_storage.dart`)
  - Biometric / Local Authentication: `local_auth: ^3.0.1` for app lock security in `lib/features/security/presentation/security_gate_wrapper.dart` and `lib/core/services/security_service.dart`

## Monitoring & Observability

**Error Tracking:**
- Local structured logging only (no 3rd-party telemetry/analytics like Sentry or Firebase Crashlytics)

**Logs:**
- Custom file-based and console logging via `logger: ^2.8.0` encapsulated in `lib/core/utils/app_logger.dart`
- In-app log viewer and export utility in `lib/features/settings/presentation/logs_screen.dart`

## CI/CD & Deployment

**Hosting:**
- GitHub Releases (`roshancodespace/shonenx`) for binaries, installers, and AppImages
- Flathub / Flatpak repository for Linux distribution (`flatpak/io.github.roshancodespace.shonenx.yml`)
- GitHub Pages for documentation (`.github/workflows/deploy-docs.yml`)

**CI Pipeline:**
- GitHub Actions:
  - `.github/workflows/release.yaml`: Automated multi-platform build triggered on release tags (builds Linux x64 Flatpak/AppImage/tar, Windows x64 Inno installer/zip, Android arm64/armv7/x86_64 APKs, macOS zip/dmg, iOS ipa)
  - `.github/workflows/deploy-docs.yml`: Documentation build and deployment to GitHub Pages
  - `.github/workflows/Notify.yml`: Discord/Telegram release notifications

## Environment Configuration

**Required env vars:**
- Passed at build time via `--dart-define-from-file=keys.json` (see `keys.example.json` and `lib/core/utils/env.dart`):
  - `ANILIST_CLIENT_ID` - AniList client ID (desktop/mobile)
  - `ANILIST_CLIENT_SECRET` - AniList client secret
  - `MAL_CLIENT_ID` - MyAnimeList OAuth client ID
  - `MAL_CLIENT_SECRET` - MyAnimeList OAuth client secret
  - `SIMKL_CLIENT_ID` - Simkl API client ID
  - `SIMKL_CLIENT_SECRET` - Simkl API client secret
  - `COMMENTUM_API_URL` - Endpoint for comments service

**Secrets location:**
- Build-time: `keys.json` (gitignored, template in `keys.example.json`)
- Runtime user tokens: OS secure credential store via `flutter_secure_storage` (`lib/core/network/secure_storage.dart`)

## Webhooks & Callbacks

**Incoming:**
- Deep links / URL scheme handlers registered in OS and routed in `lib/core/router/app_router.dart`:
  - `shonenx://` - Primary app callback scheme (OAuth redirects, deep links)
  - `aniyomi://` - Compatibility scheme for extensions and links
  - `tachiyomi://` - Compatibility scheme for manga links
  - `mangayomi://` - Compatibility scheme for manga links
- Single instance desktop IPC message handling via `flutter_single_instance` in `lib/main.dart`

**Outgoing:**
- None (Direct client-side HTTP/HTTPS requests to upstream tracking, source, and metadata APIs)

---

*Integration audit: 2026-11-07*
