# Source Engine Workflow

The Source Engine (`lib/source_engine/`) is the facade that abstracts away whether media data is coming from a hardcoded internal source (like `AllAnime`) or a dynamic Javascript extension loaded at runtime.

## Tracing a Request

To understand how it works, let's trace a user tapping on a manga cover in the UI to fetch its chapters.

### 1. The Presentation Layer
The user taps a `MediaCard`. The UI router pushes to the `DetailsScreen`. The screen asks a Riverpod provider to load the details.

```dart
// lib/features/discovery/presentation/details_screen.dart
ref.read(detailsProvider(mediaId).notifier).fetchDetails();
```

### 2. The Matchmaker
The provider delegates to the `MatchService` (`lib/source_engine/matchmaker/match_service.dart`). The Matchmaker's job is to figure out which specific repository (source) should handle this request.

```dart
final sourceId = await matchService.findBestSource(media);
```

### 3. The Source Registry
The `MatchService` asks the `SourceRegistry` for the actual implementation of that `sourceId`.

```dart
// lib/source_engine/source_registry.dart
final adapter = sourceRegistry.getAdapter(sourceId);
```
The `adapter` implements `BaseSourceAdapter`. 

### 4. The Adapter Execution
If the source is internal, it hits an inbuilt Dart class (`lib/source_engine/inbuilt_sources/`).
If the source is an extension, the adapter sends an IPC message to the JS Bridge (`packages/anymex_extension_bridge`).

```dart
// Inside the Adapter
final chapterList = await adapter.getChapters(media.sourceSpecificId);
```

### 5. Data Normalization
The JS extension might return a messy JSON object. The `anymex_extension_bridge` parses this JSON and maps it to a strictly typed Dart object.

Finally, the `SourceEngine` returns this strongly typed `List<UnifiedChapter>` back up to the Riverpod provider, which updates the UI.

## Modifying Source Behavior

If you need to fix a broken parser for an inbuilt source:
1. Navigate to `lib/source_engine/inbuilt_sources/`.
2. Find the specific source (e.g., `allanime_source.dart`).
3. Modify the `parseChapters` or `parseVideoLinks` methods.

If you need to modify how the JS Bridge handles data, you must edit the code inside `packages/anymex_extension_bridge/`.
