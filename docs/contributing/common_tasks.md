# Common Development Tasks

This guide provides concrete recipes for common development workflows in ShonenX.

---

## 1. Adding a New Feature Slice

When introducing a new domain feature (e.g. a "Statistics" screen), follow the vertical slice pattern:

### Step 1: Create the Feature Structure
Under `lib/features/statistics/`, create the standard directories:
```
lib/features/statistics/
├── domain/       # Data classes (e.g., stats_summary.dart)
├── data/         # Repositories & API fetchers
├── providers/    # Riverpod Notifiers (stats_provider.dart)
└── presentation/ # Flutter screens & widgets (stats_screen.dart)
```

### Step 2: Define the Domain Model
In `domain/stats_summary.dart`:
```dart
class StatsSummary {
  final int totalEpisodesWatched;
  final Duration totalTimeSpent;
  final Map<String, int> genreBreakdown;

  const StatsSummary({
    required this.totalEpisodesWatched,
    required this.totalTimeSpent,
    required this.genreBreakdown,
  });
}
```

### Step 3: Wire the Riverpod Provider
In `providers/stats_provider.dart`:
```dart
final statsProvider = FutureProvider.autoDispose<StatsSummary>((ref) async {
  final historyRepo = ref.watch(historyRepositoryProvider);
  return historyRepo.calculateUserStats();
});
```

### Step 4: Build the Presentation Widget
In `presentation/stats_screen.dart`:
```dart
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Stats')),
      body: statsAsync.when(
        data: (stats) => Center(child: Text('Watched: ${stats.totalEpisodesWatched}')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

### Step 5: Register in GoRouter
Add the screen definition to `lib/core/router/app_router.dart`:
```dart
GoRoute(
  path: '/stats',
  name: 'stats',
  builder: (context, state) => const StatsScreen(),
),
```

---

## 2. Modifying Remote Configuration Flags

ShonenX uses a remote configuration model to manage feature flags, override API configurations, or handle urgent updates dynamically.

1. Open `lib/core/remote_config/models/remote_config.dart`.
2. Add your field to the Freezed model:
   ```dart
   @freezed
   class RemoteConfig with _$RemoteConfig {
     const factory RemoteConfig({
       // ... existing configuration fields
       @Default(false) bool enableExperimentalPlayer, // [!code ++]
     }) = _RemoteConfig;
   }
   ```
3. Run the code generator:
   ```bash
   dart run build_runner build -d
   ```
4. Consume the configuration flag in your feature:
   ```dart
   final remoteConfig = ref.watch(remoteConfigProvider);
   if (remoteConfig.value?.enableExperimentalPlayer == true) {
     // Run experimental feature
   }
   ```

---

## 3. Adding an Episode Metadata Provider

To add a new service for fetching episode thumbnails, descriptions, and titles (e.g. Jikan, Tenrai):

1. Navigate to `lib/features/episode_metadata/services/`.
2. Create `my_service_metadata_client.dart`.
3. Implement the `EpisodeMetadataProvider` interface:
   - `resolveId(UnifiedMedia media)`: Maps universal media metadata to the provider's specific ID.
   - `fetchEpisodes(String serviceId)`: Returns structured episode metadata.
4. Register the new client in `lib/features/episode_metadata/providers/episode_metadata_providers.dart`.
5. The UI automatically uses it as a fallback if the primary metadata provider does not have data for an entry.
