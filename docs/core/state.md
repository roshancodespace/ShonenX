# State Management with Riverpod

Managing state in a complex Flutter app using plain `setState()` quickly becomes unwieldy: passing callbacks down five levels of widget trees (prop drilling), calling `setState()` after an unmount, or dealing with untracked mutable variables.

In ShonenX, we standardize on **Riverpod**. It provides compile-time safety, clean dependency injection, and complete separation between business logic and UI widgets without relying on `BuildContext`.

Here is how we use Riverpod, and the patterns to follow when building features.

---

## The Three Core Provider Types

### 1. Read-Only Data Fetching (`FutureProvider.autoDispose`)
When you need to fetch asynchronous data when a screen loads (like searching for anime, fetching release notes, or pulling an episode list), use `FutureProvider.autoDispose`:

```dart
// lib/features/updates/services/update_service.dart
final releasesListProvider = FutureProvider.autoDispose<List<GitHubRelease>>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.fetchAllReleases();
});
```

**Why `.autoDispose`?**
When the user leaves the screen, Riverpod automatically cleans up the state and frees memory. When the user returns, it refetches fresh data. This prevents unnecessary memory retention for screens the user is not actively viewing.

---

### 2. State with Actions & Mutations (`AsyncNotifierProvider`)
When the UI needs to both read state and trigger actions (like adding/deleting a download task, or updating tracker progress), use `AsyncNotifierProvider`:

```dart
class DownloadNotifier extends AsyncNotifier<List<DownloadTask>> {
  @override
  Future<List<DownloadTask>> build() async {
    // 1. Initial data fetch when the provider is first watched
    return ref.read(downloadEngineProvider).getAllTasks();
  }

  Future<void> removeTask(String id) async {
    // 2. Perform the action
    await ref.read(downloadEngineProvider).remove(id);
    
    // 3. Invalidate or refresh state so listening widgets rebuild
    ref.invalidateSelf();
  }
}

final downloadProvider = AsyncNotifierProvider<DownloadNotifier, List<DownloadTask>>(
  DownloadNotifier.new,
);
```

Consuming it in the UI:
```dart
// Watching state (automatically handles AsyncData, AsyncLoading, AsyncError)
final downloadState = ref.watch(downloadProvider);

return downloadState.when(
  data: (tasks) => ListView.builder(...),
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Failed to load downloads: $err'),
);

// Triggering an action
ElevatedButton(
  onPressed: () => ref.read(downloadProvider.notifier).removeTask('task_123'),
  child: const Text('Delete'),
);
```

---

### 3. Dependency Injection (`Provider`)
Riverpod is also our dependency injector. Instead of global singletons, services and repositories are wired through standard `Provider`s:

```dart
// The base database instance (overridden in main.dart)
final databaseProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

// A service that depends on the database and HTTP client
final historyEngineProvider = Provider<HistoryEngine>((ref) {
  final db = ref.watch(databaseProvider);
  final http = ref.watch(httpClientProvider);
  return HistoryEngine(db: db, http: http);
});
```

This makes unit testing straightforward: you can create a test `ProviderContainer` with mock implementations without touching the UI layer.

---

## Cleaning Up Native Resources (`ref.onDispose`)

When a provider instantiates an engine that interacts with native C/C++ libraries (such as `libmpv` in `media_kit`, background isolates, or local loopback servers), you **must** register a cleanup callback using `ref.onDispose`:

```dart
final videoEngineProvider = Provider.autoDispose<VideoEngine>((ref) {
  final engine = VideoEngine();
  
  // Ensures native C memory and background threads are released
  ref.onDispose(() {
    engine.dispose();
  });
  
  return engine;
});
```

Failing to register `onDispose` for native controllers can lead to memory leaks where native thread handles remain open after the UI widget is destroyed.

---

## Lifecycle: `.autoDispose` vs. Persistent Providers

| Provider Purpose | Lifecycle | Rationale |
| :--- | :--- | :--- |
| **Search results, episode lists, details screen** | `.autoDispose` | Only relevant while the user views that screen. Cleared on navigation. |
| **Download queue, tracking sync queue** | Persistent (No `.autoDispose`) | Downloads and sync tasks run in the background and must survive screen changes. |
| **User preferences, Auth tokens, DoH settings** | Persistent | Required globally across the lifetime of the app session. |
