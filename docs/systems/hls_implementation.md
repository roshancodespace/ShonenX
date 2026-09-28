# HLS Stream Implementation

The `HlsStream` is the official HLS-specific implementation of the abstract `ProxyStream`. It leverages the plug-and-play stream proxy to seamlessly handle complex `.m3u8` playlist rewriting and on-the-fly AES-128 decryption.

When the generic `StreamServer` receives an HTTP request, it extracts the stream ID from the URL (`/stream/:id/...`) and blindly calls `handleRequest` on the matching `HlsStream`. 

Here is how `HlsStream` internally routes these requests based on the URL action:

## 1. Playlist Requests (`action == 'playlist.m3u8'`)
If the player requests the playlist, `HlsStream` delegates to `HlsPlaylist.processPlaylist`.
1. It fetches the upstream `.m3u8` playlist.
2. It rewrites all segment URLs (`.ts`) and encryption key URIs to point back to the local proxy (e.g., changing them to `.../segment?url=...`).
3. It serves this modified playlist to the player.

## 2. Segment Requests (`action == 'segment'`)
When the player reads the rewritten playlist and asks for a video chunk, the URL looks like this:
`http://127.0.0.1:43092/stream/123/segment?url=encoded_segment_url&key=encoded_key&iv=...`

`HlsStream` intercepts this and triggers `_processSegment()`:
1. **Download**: It downloads the `.ts` video segment from the upstream CDN using the injected headers.
2. **Key Caching**: If a `key` is present in the query parameters, it checks its in-memory `_keyCache`. If the key isn't cached, it securely fetches it. This prevents spamming the upstream server for the same key.
3. **Decryption**: It passes the segment bytes, the AES-128 key, and the IV to `HlsCrypto.decrypt()`.
4. **Streaming**: The raw, decrypted video bytes are piped directly back to the local video player as a standard `video/MP2T` response.
