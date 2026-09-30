# Progress Tracking: Multi-Service Synchronization

Synchronizing watch and read progress across external services (AniList, MyAnimeList, Simkl, and Kitsu) requires careful coordination:
1. **Rate Limiting:** Remote APIs enforce rate limits. Firing requests on every seek or tick would quickly exhaust quotas.
2. **Preventing Regressions:** If a user watched up to Episode 20 on desktop, an offline mobile device with local state at Episode 12 must not overwrite remote progress when reconnecting.
3. **Diverse Auth Flows:** Each service uses a different authorization protocol (OAuth 2.0 PKCE, GraphQL Bearer tokens, or API keys).

ShonenX's tracking system (`lib/features/tracking/`) centralizes this logic into a unified sync pipeline.

---

## Core Architecture

```mermaid
graph TD
    Player[Video Player Engine] -->|Playback Progress Event| Sync[SyncEngine]
    
    subgraph Threshold & Evaluation
        Sync --> Calc{Progress >= 80%?}
        Calc -->|No| Skip[Update Local UI Only]
        Calc -->|Yes| Queue[Check Cloud Version Ahead?]
    end

    subgraph Dispatcher
        Queue -->|Local >= Cloud| Broadcaster[Multi-Tracker Dispatcher]
        Broadcaster --> AL[AniList (GraphQL)]
        Broadcaster --> MAL[MyAnimeList (REST PKCE)]
        Broadcaster --> Simkl[Simkl API]
        Broadcaster --> Kitsu[Kitsu JSON:API]
    end

    subgraph Security
        Broadcaster -.-> FSS[(FlutterSecureStorage<br/>OS Keychain / Keyring)]
    end
```

---

## Synchronization Mechanics

### 1. Completion Threshold
During video playback, the player engine periodically emits playback progress events:

```dart
ref.read(syncEngineProvider).processPlayback(
  media: currentMedia,
  episodeNumber: 5,
  position: currentPosition,
  duration: totalDuration,
);
```

Instead of sending remote updates on every tick:
- The `SyncEngine` tracks elapsed duration.
- Only when playback crosses the completion threshold (80-85% of total duration), it triggers a status update to mark the episode completed.
- Casual scrubbing or brief previews do not trigger unnecessary network updates.

### 2. Safeguarding Against Regressive Overwrites
Before dispatching an update to remote trackers, the `SyncEngine` compares the target episode number with the current cloud state. If the remote service already reports a higher completed episode, ShonenX avoids sending a lower number, preserving newer progress made on other devices.

### 3. Secure Token Storage
OAuth credentials and access tokens are never stored in plain text. They are encrypted at rest using **`FlutterSecureStorage`**, which maps to native platform keychains:
- **Android:** Android Keystore (AES-GCM)
- **iOS & macOS:** Apple Keychain
- **Linux:** Secret Service API (gnome-keyring / libsecret)
- **Windows:** Windows Credential Manager

---

## Adding a New Tracker Integration

To integrate a new tracking service (such as Shikimori):

### 1. Register the Tracker Type
Add the identifier to `TrackerType` in `lib/features/tracking/domain/models/tracker_type.dart`:
```dart
enum TrackerType {
  anilist,
  mal,
  simkl,
  kitsu,
  shikimori, // [!code ++]
}
```

### 2. Implement the Authenticator
Create `lib/features/tracking/engine/trackers/shikimori/shikimori_authenticator.dart` to handle OAuth authorization and token exchange, saving the credentials via `FlutterSecureStorage`.

### 3. Implement the Tracker Client
Create `lib/features/tracking/engine/trackers/shikimori/shikimori_tracker.dart`, implementing `BaseTracker` and `RemoteTracker`:

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
    final token = await getToken();
    if (token == null) throw Exception('User not authenticated with Shikimori');

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
      },
    );
  }
}
```

### 4. Register in Tracker Registry
Add the new tracker to `lib/features/tracking/providers/tracker_registry.dart`. The UI settings, multi-tracker broadcaster, and sync engine will automatically recognize and manage it.
