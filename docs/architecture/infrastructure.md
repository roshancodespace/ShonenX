# Core Infrastructure

The `lib/core/` directory houses the underlying subsystems that power the application but are not tied to a specific business domain.

## Networking

Network requests are abstracted to decouple the application from raw HTTP clients.

- **`Rhttp`:** ShonenX utilizes [`rhttp`](https://pub.dev/packages/rhttp) for high-performance networking (leveraging Rust).
- **Initialization:** Rhttp must be initialized asynchronously at startup in [`app_init.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/app_init.dart).
- **Client Wrapping:** Features do not use `rhttp` directly. They inject HTTP clients (or `CFClient` for Cloudflare bypass handling) via Riverpod.

## Caching

To reduce API strain and improve load times, responses can be cached locally.

- **`CacheManager`:** Implemented in [`lib/core/caching/cache_manager.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/core/caching/cache_manager.dart).
- **Mechanism:** Serializes API responses and persists them to the Isar database alongside an expiration timestamp.
- **Consumption:** The `CacheManager` intercepts network calls. If a valid cache entry exists, it returns immediately; otherwise, it executes the network call and updates the cache.

## Routing

Navigation is declarative, powered by GoRouter.

- **Configuration:** The routing tree is strictly defined in [`app_router.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/core/router/app_router.dart).
- **Deep Linking:** GoRouter is configured to intercept custom URI schemes (e.g., `aniyomi://`, `cloudstream://`) and redirect them to the Extension Settings screen to automatically handle repository additions.
- **Shell Routes:** The main application layout (Bottom Navigation Bar) is driven by a `StatefulShellRoute` via `ScaffoldWithNavBar`.

## App Initialization

The application lifecycle begins in [`lib/main.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/main.dart), but heavy lifting is delegated to `AppInit`.

[`AppInit.init()`](https://github.com/roshancodespace/shonenx/blob/main/lib/app_init.dart) executes sequentially before `runApp`:
1.  Initializes `Rhttp`.
2.  Configures `window_manager` (including platform-specific behavior for Linux tiling WMs).
3.  Initializes `media_kit` for native video decoding.
4.  Opens the Isar database.
5.  Fires asynchronous setups (cleanup scripts, notifications).
6.  *Post-launch:* `setupBridge` is called lazily to initialize the Extension Bridge JS runtime.
