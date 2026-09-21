# Networking, Caching & Persistence

## Networking (`rhttp`)

ShonenX abstracts HTTP calls to decouple features from the raw network client. We use [`rhttp`](https://pub.dev/packages/rhttp) because it leverages Rust for high-performance networking and better TLS fingerprinting evasion, which is critical when interacting with certain external trackers and sources.

**Usage:**
Features inject the `httpClientProvider` rather than using `http.get` directly:
```dart
class JikanMetadataClient implements EpisodeMetadataProvider {
  final HTTP _http;

  // Injection
  JikanMetadataClient({HTTP? http}) : _http = http ?? HTTP();
  
  Future<void> fetch() async {
    // Under the hood, this uses rhttp and automatically checks the CacheManager
    final res = await _http.get('https://api.jikan.moe/...', cacheDuration: Duration(days: 30));
  }
}
```

## Caching (`CacheManager`)

The `CacheManager` intercepts network calls made via `HTTP`.

1. When `_http.get(url, cacheDuration: X)` is called, `CacheManager` hashes the URL.
2. It queries Isar for a valid `CacheEntry`.
3. If an entry exists and is not expired, it returns the cached response immediately.
4. If expired or missing, it executes the network call, saves the response to Isar, and returns the data.

This greatly reduces API strain on third-party services like Jikan and Kitsu.

## Persistence (`Isar`)

[Isar](https://isar.dev/) is our local database for caching, library entries, and user history.

### Creating a Model
If you need to persist a new object, annotate it with `@collection` and `@Id()`:

```dart
import 'package:isar/isar.dart';

part 'download_task.g.dart';

@collection
class DownloadTask {
  Id id = Isar.autoIncrement; // Auto-incrementing ID

  @Index(unique: true, replace: true)
  late String url;
  
  late String status;
}
```

### Generating Schemas
After modifying *any* Isar model, you must regenerate the code. If you forget, the app will fail to compile.
```bash
dart run build_runner build -d
```

### Accessing the Database
The `Isar` instance is provided via Riverpod (`databaseProvider`).

```dart
final db = ref.read(databaseProvider);

// Writing data
await db.writeTxn(() async {
  await db.downloadTasks.put(myTask);
});

// Reading data
final tasks = await db.downloadTasks.where().findAll();
```
