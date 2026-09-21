# Tracking Workflow

ShonenX synchronizes media progress (watch/read status) with external services like AniList, MyAnimeList, Simkl, and Kitsu. The implementation lives entirely within `lib/features/tracking/`.

## Architecture

The tracking ecosystem uses a strict inheritance model.

1. **`TrackerType`**: An enum defining the supported services (e.g., `TrackerType.anilist`).
2. **`BaseTracker`**: The abstract class outlining capabilities (`updateProgress`, `fetchList`).
3. **`RemoteTracker`**: Inherits from `BaseTracker` and represents a network-bound tracker.
4. **Concrete Trackers**: E.g., `AniListTracker` in `lib/features/tracking/engine/trackers/anilist/`.

## Authentication Flow

Because authentication belongs to the external services (not ShonenX itself), it is handled by the `tracker_auth_provider.dart` inside the tracking feature.

1. The user goes to Settings and clicks "Connect to AniList".
2. The UI triggers `ref.read(authTokensProvider.notifier).login(aniListTracker)`.
3. `login()` calls `aniListTracker.authenticator.performLogin()`, which usually opens an OAuth webview.
4. The token is received, saved to `FlutterSecureStorage` (with a prefix like `auth_token_anilist`), and the state is updated.
5. The `TrackingService` now knows to include `AniListTracker` in all multi-tracker broadcast operations.

## Broadcasting Progress

When a user watches an episode in the Video Player, the player doesn't talk to AniList directly. It talks to the `SyncEngine`.

```dart
// Inside the Player Engine upon completing an episode:
ref.read(syncEngineProvider).processPlayback(
  media: currentMedia,
  episodeNumber: 12,
  position: currentPosition,
  duration: totalDuration,
);
```

The `SyncEngine` evaluates if the user has hit the sync threshold. If they have, it iterates over all *active* (logged in and toggled on) `RemoteTracker` instances and broadcasts the update concurrently, checking if the cloud is already ahead to prevent bad overwrites.

## Adding a New Tracker

To add a new integration (e.g., `Shikimori`):

1. Add `shikimori` to the `TrackerType` enum in `lib/features/tracking/domain/models/tracker_type.dart`.
2. Create `lib/features/tracking/engine/trackers/shikimori/`.
3. Implement `ShikimoriAuthenticator` (OAuth logic).
4. Implement `ShikimoriTracker` extending `RemoteTracker`:

```dart
class ShikimoriTracker extends BaseTracker implements RemoteTracker {
  final Ref ref;
  final HTTP _http;

  ShikimoriTracker(this.ref) : _http = ref.read(httpClientProvider);

  @override
  TrackerType get type => TrackerType.shikimori;

  @override
  Future<void> updateListItem({
    required UnifiedMedia media,
    required String trackingId,
    TrackedStatus? status,
    double? progress,
    double? score,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    // Make the API call to Shikimori using the injected HTTP client
    await _http.post(
      'https://shikimori.one/api/v2/user_rates',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        'user_rate': {
          'target_id': trackingId,
          'target_type': 'Anime',
          if (progress != null) 'episodes': progress.toInt(),
          if (score != null) 'score': score.toInt(),
        }
      }
    );
  }
  
  // ... implement fetchProfile, fetchUserLibrary, etc.
}
```

5. Finally, register the new tracker in `lib/features/tracking/providers/tracker_registry.dart`.
