# Networking, Caching & Persistence

If you are writing features in ShonenX, **never use `dart:io` or the generic `http` package directly.**

If you fire raw HTTP calls inside random UI widgets, you bypass our DoH resolver, risk getting blocked by Cloudflare bot protection, and miss out on disk-level response caching.

Here is how our data layer actually works and why it is structured this way.

---

## 1. Networking (`rhttp`) & DNS Over HTTPS

Most Flutter apps use standard Dart HTTP clients. That works fine for typical APIs, but it struggles when scraping anime websites or pulling metadata from hosts protected by modern CDNs.

Cloudflare and similar services inspect the **TLS Client Hello fingerprint** (JA3/JA4). Standard Dart networking looks like an automated script, which often triggers a `403 Forbidden` challenge.

To solve this, we use [`rhttp`](https://pub.dev/packages/rhttp). It delegates networking to native **Rust** (`reqwest` and `hyper`), using standard browser TLS handshakes so requests pass through cleanly.

On top of that, all network calls automatically route through our custom **DNS over HTTPS (DoH)** resolver (defaulting to Cloudflare `1.1.1.1` and Google `8.8.8.8`), protecting lookups from ISP-level filtering.

👉 Read the full breakdown: **[DNS over HTTPS (DoH) & Client Injection](/systems/dns_over_https)**

### How to Make Network Calls

Always inject `httpClientProvider` via Riverpod:

```dart
class JikanMetadataClient implements EpisodeMetadataProvider {
  final HTTP _http;

  JikanMetadataClient({HTTP? http}) : _http = http ?? HTTP();
  
  Future<void> fetch() async {
    // Under the hood, this uses Rust rhttp + DoH + automatic disk caching:
    final res = await _http.get(
      'https://api.jikan.moe/v4/anime/21/episodes', 
      cacheDuration: const Duration(days: 7),
    );
  }
}
```

---

## 2. Caching (`CacheManager`): Respecting Community APIs

Community APIs like Jikan (Unofficial MyAnimeList API) and Kitsu are hosted on limited volunteer infrastructure. If the app hammered them on every screen navigation, users would quickly get rate-limited.

`HTTP` has an integrated `CacheManager` backed by our local database:

1. When you call `_http.get(url, cacheDuration: Duration(days: 7))`, the manager hashes the URL.
2. It checks our local Isar database for an existing cached entry.
3. If the cache exists and has not expired, it returns the cached data **instantly in 0ms without touching the network.**
4. If it has expired or does not exist, it makes the network request, saves the response to disk, and returns the fresh data.

If you are fetching data that rarely changes (like episode titles, synopsis, or cover images), **always pass a `cacheDuration`**.

---

## 3. Persistence (`Isar Database`)

We use [Isar](https://isar.dev/) for local database storage (cache entries, watch history, manga library, and download tasks).

Isar is a fast, zero-copy NoSQL database that works directly with native Dart objects, avoiding the boilerplate of manual SQLite queries.

### Creating an Isar Model

To persist an entity to disk, annotate it with `@collection` and define an `@Id()`:

```dart
import 'package:isar/isar.dart';

part 'download_task.g.dart';

@collection
class DownloadTask {
  Id id = Isar.autoIncrement; // Auto-incrementing primary key

  @Index(unique: true, replace: true)
  late String url;
  
  late String status;
}
```

### The Rule: Regenerate Code on Model Changes

Whenever you modify an Isar model (add a field, rename a property, change an index), you **must regenerate the code**:

```bash
dart run build_runner build -d
```

### Accessing the Database

Never instantiate `Isar` directly in widgets. Always read it through Riverpod's `databaseProvider`:

```dart
final db = ref.read(databaseProvider);

// Writing data (always inside a transaction!):
await db.writeTxn(() async {
  await db.downloadTasks.put(myTask);
});

// Reading data:
final tasks = await db.downloadTasks.where().findAll();
```
