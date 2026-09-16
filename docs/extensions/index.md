# Source Engine

The [`lib/source_engine`](https://github.com/roshancodespace/shonenx/tree/main/lib/source_engine/) acts as a universal abstraction layer. Because ShonenX integrates multiple discrete sources (both native code and external extensions), the core application cannot be tightly coupled to any individual source's API.

## Unified Media

Features consume data via the [`UnifiedMedia`](https://github.com/roshancodespace/shonenx/blob/main/lib/shared/models/unified_media.dart) model. The `source_engine` is responsible for parsing raw foreign payloads and normalizing them into this model. 

## Source Types

1.  **Inbuilt Sources:** Located in [`lib/source_engine/inbuilt_sources/`](https://github.com/roshancodespace/shonenx/tree/main/lib/source_engine/inbuilt_sources/). These are hardcoded Dart implementations for specialized APIs.
2.  **Extensions:** Sandboxed, dynamically loaded scripts originating from external communities (Mangayomi, Cloudstream, Aniyomi). See the [Extension Bridge](./bridge.md).

## Adding an Inbuilt Source

1.  Create a new file in `lib/source_engine/inbuilt_sources/`.
2.  Implement the required interface based on the target media type (Anime, Manga, Novel).
3.  Register your implementation in `inbuiltSourcesProvider` inside [`source_registry.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/source_engine/source_registry.dart).
