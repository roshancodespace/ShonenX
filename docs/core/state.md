# State Management with Riverpod

ShonenX relies strictly on Riverpod for state management, dependency injection, and data fetching. The presentation layer (UI) must never instantiate engine classes directly.

## How We Use Providers

Providers live inside the `providers/` directory of each feature. We predominantly use `NotifierProvider`, `AsyncNotifierProvider`, and `FutureProvider`.

### 1. Simple Data Fetching
If you just need to fetch data asynchronously (e.g., fetching release metadata), use a `FutureProvider`. 

**Example from `lib/features/updates/services/update_service.dart`:**
```dart
final releasesListProvider = FutureProvider.autoDispose<List<GitHubRelease>>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.fetchAllReleases();
});
```

### 2. Complex State with Mutation
When the UI needs to both read state and trigger actions (like deleting a download), we use an `AsyncNotifierProvider`.

**Example Pattern:**
```dart
class DownloadNotifier extends AsyncNotifier<List<DownloadTask>> {
  @override
  Future<List<DownloadTask>> build() async {
    // 1. Initial data fetch
    return ref.read(downloadEngineProvider).getAllTasks();
  }

  Future<void> removeTask(String id) async {
    // 2. Perform the action
    await ref.read(downloadEngineProvider).remove(id);
    // 3. Invalidate or update state so UI rebuilds
    ref.invalidateSelf();
  }
}

final downloadProvider = AsyncNotifierProvider<DownloadNotifier, List<DownloadTask>>(
  DownloadNotifier.new,
);
```

### 3. Dependency Injection
We use Riverpod to inject instances like databases or configurations into our engines. This makes mocking/testing easier.

```dart
final databaseProvider = Provider<Isar>((ref) {
  // Provided in main.dart via ProviderScope overrides
  throw UnimplementedError();
});

final myEngineProvider = Provider<MyEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return MyEngine(db);
});
```

## `autoDispose` vs Persistent Providers

When adding a provider, carefully consider its lifecycle:

- **Use `.autoDispose`:** If the provider only tracks state for a specific screen (like a Search Screen or a specific Episode List). When the user navigates away, the state is cleared, saving memory.
  ```dart
  final searchResultsProvider = FutureProvider.autoDispose<List<Media>>(...)
  ```
- **Keep Persistent:** If the provider manages application-wide state (like SharedPreferences, Auth Tokens, or the Download Queue).

### Cleaning up Native Resources
If your provider holds a native resource (like a WebSocket or a Video Engine), you **must** use `ref.onDispose` to clean it up, even if it's persistent, in case the provider is forcefully invalidated.

```dart
final videoEngineProvider = Provider.autoDispose<VideoEngine>((ref) {
  final engine = VideoEngine();
  
  ref.onDispose(() {
    engine.dispose();
  });
  
  return engine;
});
```
