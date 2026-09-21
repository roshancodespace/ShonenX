# Media Playback & Downloads

ShonenX provides advanced media playback capabilities, natively handling HTTP streams, HLS, and peer-to-peer torrent streaming. Both playback and downloads are intertwined due to their shared network requirements.

## The Video Engine (`media_kit`)

The application standardizes on `media_kit` for native cross-platform playback.

- **Initialization:** Executed eagerly during `AppInit._initVideoEngines()`.
- **Abstraction:** The underlying `media_kit` API is wrapped within `lib/features/player/engine/video_engine.dart`. The UI layer should never instantiate `media_kit` classes directly.

### Interacting with the Player

The Video Player state (volume, playback speed, subtitles) is managed by `videoEngineProvider` and `playerStateProvider`.

```dart
// Pause the video from anywhere in the app
ref.read(videoEngineProvider).pause();

// Seek
ref.read(videoEngineProvider).seekTo(Duration(minutes: 5));
```

## Torrent Streaming

A standout feature is the ability to stream peer-to-peer torrents natively. However, it is important to note that **the torrent logic is not custom to ShonenX.**

The heavy lifting is done entirely by the **`anymex_extension_bridge`**. While ShonenX bundles the `libtorrent_flutter` FFI bindings required to talk to the OS, the actual logic of parsing the magnet, spinning up the local HTTP server, prioritizing chunks, and feeding the stream URL is managed by the Bridge's player controller.

1.  A torrent magnet or `.torrent` file URL is resolved by an extension.
2.  The `anymex_extension_bridge` (via `libtorrent_flutter`) establishes a local HTTP server.
3.  The bridge prioritizes the video file chunks from the swarm.
4.  The `video_engine` is provided the local localhost HTTP URL (e.g., `http://127.0.0.1:8080/stream`).
5.  `media_kit` buffers and plays the stream natively.

If you are debugging torrent streaming issues, look at the player controller inside `packages/anymex_extension_bridge/`, not the ShonenX UI layer.

## Downloads

Offline downloads use different engines depending on the payload type (Direct HTTP vs M3U8/HLS). This logic lives in `lib/features/downloads/engine/`.

### The Isar Lifecycle

1. When a user clicks "Download", the UI creates a `DownloadTask` Isar object and saves it via `downloadProvider`.
2. The `DownloadEngine` picks up the pending task.
3. If it's an HLS stream, the `M3U8DownloadEngine` spawns background isolates (using `flutter_isolate`) to concurrently download `.ts` segments.
4. As segments complete, the `DownloadTask.progress` is updated in Isar.
5. `downloadProvider` watches this Isar collection and automatically rebuilds the Downloads screen UI.

Because downloading is long-running, the `downloadProvider` is intentionally kept persistent (no `autoDispose`), ensuring the background isolates survive screen navigation.
