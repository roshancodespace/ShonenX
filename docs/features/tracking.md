# Tracking & Synchronization

ShonenX keeps a user's library synchronized across devices by integrating with major tracking services (AniList, MyAnimeList, Simkl, Kitsu). 

## Tracker Abstraction

The tracking engine is decoupled from the UI. Features request tracking updates through a unified interface.

*   **`BaseTracker`**: Defines the contract (`fetchList`, `updateProgress`, `updateScore`).
*   **`RemoteTracker`**: Extends `BaseTracker` for API-based services.
*   **Implementations**: Code specific to a service's API quirks (REST vs GraphQL) lives in [`lib/features/tracking/engine/trackers/`](https://github.com/roshancodespace/shonenx/tree/main/lib/features/tracking/engine/trackers/).

## Synchronization Engine

The [`SyncEngine`](https://github.com/roshancodespace/shonenx/blob/main/lib/features/tracking/engine/sync_engine.dart) is the critical bridge reconciling remote APIs with the local database.

1.  **Local State:** Progress is stored in Isar (`WatchHistoryEntry` or `ReadHistoryEntry`).
2.  **Trigger:** Upon finishing a chapter/episode, the player/reader notifies the `SyncEngine`.
3.  **Resolution:** The `SyncEngine` queries the [Matchmaker](../extensions/matchmaker.md) to translate the source's local ID into the global tracker ID (e.g., AniList ID).
4.  **Dispatch:** An API request is fired to the active trackers. If the network fails, the request is queued.

## Authentication

Tracking services require OAuth 2.0 authentication.

*   Flows are handled in [`lib/features/auth/`](https://github.com/roshancodespace/shonenx/tree/main/lib/features/auth/) utilizing `flutter_web_auth_2`.
*   Tokens are persisted to the keystore using `flutter_secure_storage`.
