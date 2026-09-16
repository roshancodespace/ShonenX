# Media Playback

ShonenX provides advanced media playback capabilities, natively handling both traditional HTTP streams and peer-to-peer torrent streaming.

## Video Engine (`media_kit`)

The application standardizes on [`media_kit`](https://github.com/media-kit/media-kit) for highly performant, universal video playback across all supported platforms (Android, iOS, Windows, Linux, macOS).

*   **Initialization:** Executed eagerly during `AppInit._initVideoEngines()`.
*   **Abstraction:** To prevent tight coupling, the underlying `media_kit` API is wrapped within [`video_engine.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/features/player/engine/video_engine.dart). Features consume this engine rather than interacting with the player directly.
*   **State Management:** Volume, brightness, playback speed, and subtitle selection are bound to Riverpod state providers in `lib/features/player/providers/`.

## Torrent Streaming

A standout feature is the ability to stream peer-to-peer torrents directly into the video player without requiring a full download first.

*   **Underlying Engine:** Powered by the FFI bindings in [`libtorrent_flutter`](https://github.com/roshancodespace/shonenx/tree/main/packages/anymex_extension_bridge/packages/libtorrent_flutter).
*   **Workflow:**
    1.  A torrent magnet or file is resolved from an extension.
    2.  The torrent engine establishes a local HTTP server and begins prioritizing the specific media file's chunks sequentially.
    3.  The `video_engine` is provided the local HTTP URL (e.g., `http://127.0.0.1:8080/stream`).
    4.  `media_kit` buffers and plays the stream natively.

## Reader Integration

For Manga, the `reader` feature operates similarly. It handles pagination and pre-fetching of images, heavily utilizing the `CacheManager` to ensure smooth chapter transitions even on unstable networks.
