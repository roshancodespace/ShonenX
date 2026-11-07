---
last_mapped_commit: 184e63f99949cf25990cd41afc1bbdaf15a3cf70
last_mapped_at: 2026-11-07
---
# Codebase Concerns

**Analysis Date:** 2026-11-07

## Tech Debt

**Residual GetX Dependency:**
- Issue: `import 'package:get/get.dart';` is imported in `lib/app_init.dart:8`, and `get: ^4.7.3` is declared in `pubspec.yaml`, despite the application architecture standardizing strictly on Riverpod (`flutter_riverpod: ^3.3.1`).
- Files: `lib/app_init.dart`, `pubspec.yaml`
- Impact: Unneeded binary bloat and potential confusion for developers regarding the active state management pattern.
- Fix approach: Remove the unused GetX import from `lib/app_init.dart`, audit other files for GetX usage, and remove `get` from `pubspec.yaml`.

**Inbuilt Source Extraction Stubs:**
- Issue: Source methods in MrIruro source contain unimplemented stub comments: `// TODO: implement getServers` and `// TODO: implement getSources`.
- Files: `lib/source_engine/inbuilt_sources/anime/mriruro_source.dart:126-132`
- Impact: Calling MrIruro source for streaming returns incomplete or unhandled source streams.
- Fix approach: Complete the implementation of `getServers` and `getSources` or disable the source until fully implemented.

**Monolithic UI Screens:**
- Issue: Several presentation screens have grown excessively large with complex inline state and widget trees (e.g. `DownloadsScreen` is >1000 lines and 40KB; `BackupService` is 620 lines; `AppRouter` is 512 lines).
- Files: `lib/features/downloads/presentation/downloads_screen.dart`, `lib/core/services/backup_service.dart`, `lib/core/router/app_router.dart`
- Impact: Difficult to maintain, review, and test; higher probability of regressions during UI refactoring.
- Fix approach: Decompose monolithic screens into dedicated sub-widgets and separate state management controllers.

## Known Bugs

**Linux Tiling Window Manager Quirks:**
- Symptoms: When launched on Linux tiling window managers (Hyprland, Niri), standard title bars and window decor may cause visual glitches or misplaced window frames.
- Files: `lib/app_init.dart:97-116`
- Trigger: Running on a Linux desktop where `XDG_CURRENT_DESKTOP` or `DESKTOP_SESSION` contains "hyprland" or "niri".
- Workaround: Explicit environment variable sniffing in `lib/app_init.dart` hides window title bars dynamically for Hyprland and Niri.

**Timezone Identifier Resolution Failures:**
- Symptoms: Background notifications fail to schedule if the host device returns legacy or non-standard timezone identifiers (such as `Asia/Calcutta` or `US/Eastern`).
- Files: `lib/core/services/notification_service.dart:28-44`
- Trigger: Device operating system locale returning legacy timezone strings unrecognized by `package:timezone`.
- Workaround: Hardcoded dictionary of timezone aliases in `NotificationService.init()`.

## Security Considerations

**Unauthenticated Local Stream Proxy Server:**
- Risk: `StreamServer` starts an embedded HTTP server on localhost (`http://127.0.0.1`) to proxy HLS video playlists and inject required HTTP headers (`Referer`, `User-Agent`).
- Files: `lib/core/network/stream_server/stream_server.dart`
- Current mitigation: Binds exclusively to localhost loopback interface.
- Recommendations: Implement random per-session authorization tokens in URL paths to prevent unauthorized local processes from hijacking stream proxy endpoints.

**API Credential Handling & Secret Leaks:**
- Risk: Client IDs and secrets for AniList, MAL, and Simkl are compiled into the binary via `--dart-define-from-file=keys.json`.
- Files: `keys.example.json`, `keys.json`, `lib/core/utils/env.dart`
- Current mitigation: `keys.json` is ignored in `.gitignore`, and `keys.example.json` provides dummy values.
- Recommendations: Continue enforcing pre-commit checks to verify that `keys.json` or live API credentials are never committed into git history.

## Performance Bottlenecks

**Heavy Video Decoding & Memory Consumption:**
- Problem: High-resolution (1080p/4K) anime streaming combined with software subtitle rendering (`ass_parser.dart` / libass) can consume substantial memory on low-spec desktop/mobile devices.
- Files: `lib/features/player/engine/media_kit/media_kit_engine.dart`, `lib/features/player/utils/parsers/ass_parser.dart`
- Cause: Subtitle rasterization and hardware acceleration fallbacks in mpv/MediaKit.
- Improvement path: Enable hardware video acceleration by default where supported and optimize custom subtitle overlay rendering.

**Unbounded Network Cache Growth:**
- Problem: Large volumes of anime cover images, episode thumbnails, and cached HTTP responses can expand disk footprint over time.
- Files: `lib/core/caching/cache_manager.dart`, `lib/features/settings/presentation/cache_settings_screen.dart`
- Cause: Caching responses in Isar and temporary directories without strict background eviction timers.
- Improvement path: Implement proactive LRU cache trimming and maximum cache size enforcement in `CacheManager`.

## Fragile Areas

**Third-Party Web Scraping & Extractors:**
- Files: `lib/source_engine/inbuilt_sources/`, `lib/core/widgets/cloudflare_webview.dart`
- Why fragile: Anime streaming domains frequently change domain names, rotate CSS selectors, alter encryption algorithms, and activate Cloudflare Turnstile anti-bot checks.
- Safe modification: Encapsulate scrapers behind `BaseSourceAdapter` and use external extension repositories so scrapers can be updated without rebuilding the full application binary.
- Test coverage: Zero automated test coverage for scrapers.

**Git-Pinned Dependencies & Overrides:**
- Files: `pubspec.yaml:26-40, 73-77, 95-132`
- Why fragile: Pinned to specific git repositories (`Predidit/media-kit.git`, `kodjodevf/flutter-discord-rpc.git`, `EchoEllet/flutter_secure_storage.git`) rather than stable published packages on pub.dev.
- Safe modification: Pin exact commit hashes rather than floating branches and test compilation thoroughly on all target platforms when updating dependencies.
- Test coverage: Uncovered.

## Scaling Limits

**Isar Database File Cap:**
- Current capacity: `maxSizeMiB: 4096` (4 GB) specified in `lib/app_init.dart:151`.
- Limit: If user library, detailed cache, and historical tracking entries exceed 4 GB, Isar operations will fail.
- Scaling path: Periodic vacuuming and clearing stale `CacheEntry` rows.

## Dependencies at Risk

**`media_kit` (Git fork):**
- Risk: Pinned to git fork `https://github.com/Predidit/media-kit.git` (commit `78d4cce7b49d5b6b918f78b18ec1fbb7c400b9da`).
- Impact: Core video playback functionality depends on external fork stability.
- Migration plan: Track upstream `media-kit/media-kit` releases and migrate back to official pub.dev packages once upstream incorporates required fixes.

**`flutter_inappwebview` (Beta version):**
- Risk: Pinned via `dependency_overrides` to `6.2.0-beta.2`.
- Impact: Beta platform channel APIs may introduce instability or deprecation warnings across OS upgrades.
- Migration plan: Update to stable releases when released by upstream maintainers.

## Missing Critical Features

**Automated Test Suite:**
- Problem: The main application has zero unit, widget, or integration tests in the root repository.
- Blocks: Refactoring core services (e.g. `TrackingService`, `CacheManager`, `AppInit`) poses high risk of undetected regressions.

## Test Coverage Gaps

**Application Core Services:**
- What's not tested: `CacheManager` TTL eviction, `TrackingService` multi-tracker scrobbling, `DohResolver` DNS resolution fallbacks, `BackupService` serialization/deserialization.
- Files: `lib/core/caching/cache_manager.dart`, `lib/features/tracking/engine/tracking_service.dart`, `lib/core/network/doh/doh_resolver.dart`, `lib/core/services/backup_service.dart`
- Risk: Corrupt user data or broken sync without immediate user warning.
- Priority: High

**Source Engine Matchmaker & Parsers:**
- What's not tested: Title normalization (`title_matcher.dart`), ASS/SRT subtitle parsing, stream extractor logic.
- Files: `lib/features/episode_metadata/services/title_matcher.dart`, `lib/features/player/utils/subtitle_parser.dart`
- Risk: Playback failures, mismatching episodes to trackers, or unreadable subtitles.
- Priority: Medium

---

*Concerns audit: 2026-11-07*
