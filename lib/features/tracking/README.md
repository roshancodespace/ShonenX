# Tracking Architecture & Developer Guide

This directory manages all media tracking providers (e.g. AniList, MyAnimeList, Kitsu, Local).

## Directory Layout

```
lib/features/tracking/
├── domain/                    # Domain models & state (TrackerType, TrackerProfile, etc.)
├── engine/
│   ├── contracts/             # Core Interfaces & Base Classes
│   │   ├── tracking_service.dart  # Core tracking contract
│   │   ├── remote_tracker.dart    # Remote tracker contract (search, discover, profile)
│   │   └── base_tracker.dart      # Base class with logging & error execution wrapper
│   └── trackers/              # Modular Tracker Implementations
│       ├── anilist/
│       ├── kitsu/
│       ├── local/
│       ├── mal/
│       └── index.dart         # Barrel export for all trackers
└── providers/
    └── tracker_registry.dart  # Central tracker factory & Riverpod providers
```

---

## How to Add a New Tracker

Adding a new tracking service (e.g. `SIMKL` or `Trakt`) requires 3 steps:

### 1. Add Entry to `TrackerType`
In `lib/features/tracking/domain/models/tracker_type.dart`, add the new enum value and optional icon string:

```dart
enum TrackerType {
  anilist('AniList'),
  myanimelist('MyAnimeList'),
  kitsu('Kitsu'),
  simkl('SIMKL'), // <-- New Tracker
  local('Local');
  ...
}
```

### 2. Implement Tracker Contracts
Create a directory under `lib/features/tracking/engine/trackers/<tracker_name>/` and extend `BaseTracker` while implementing `RemoteTracker` (or `TrackingService`):

```dart
class SimklTracker extends BaseTracker implements RemoteTracker {
  final Ref ref;

  SimklTracker(this.ref);

  @override
  TrackerType get type => TrackerType.simkl;

  @override
  Future<bool> get isAuthenticated async => ...;

  @override
  bool supportsMediaType(MediaType mediaType) => true;

  @override
  Future<void> updateListItem({...}) async {
    return executeApi('updateListItem', () async {
      // Implementation logic
    });
  }

  // Implement remaining RemoteTracker methods...
}
```

Export your new tracker in `lib/features/tracking/engine/trackers/index.dart`:

```dart
export 'simkl/simkl_tracker.dart';
```

### 3. Register in `TrackerRegistry`
In `lib/features/tracking/providers/tracker_registry.dart`, register your tracker inside `createTracker`:

```dart
class TrackerRegistry {
  static TrackingService createTracker(TrackerType type, Ref ref) {
    switch (type) {
      case TrackerType.anilist:
        return AnilistTracker(ref);
      case TrackerType.myanimelist:
        return MalTracker(ref);
      case TrackerType.kitsu:
        return KitsuTracker(ref);
      case TrackerType.simkl:
        return SimklTracker(ref); // <-- Register instance
      case TrackerType.local:
        return LocalTracker(ref.watch(databaseProvider));
    }
  }
}
```

That's it! The Riverpod providers (`availableTrackersProvider`, `primaryTrackerProvider`, `activeTrackersProvider`) will automatically recognize and include your new tracker throughout the app UI and background sync engine.
