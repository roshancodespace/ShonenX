# Local Stream Proxy Server

ShonenX implements a lightweight, ephemeral **Local Stream Proxy Server** (HTTP) to intercept and stream media. 

::: info Why do we need this?
Native media players (like `media_kit`/mpv) and standard HTTP downloaders fail to handle strict upstream CDN blocking natively—such as **Cloudflare challenges**, **referrer checks**, and **proprietary AES-128 encryption**. The proxy intercepts requests from the player, fetches the data using our Cloudflare-bypassing `rhttp` wrapper, decrypts if necessary, and serves it safely to the local player.
:::

## Architecture: The Plug-and-Play Abstraction

The server is built on a highly extensible, protocol-agnostic architecture. The core server doesn't know anything about HLS, DASH, or any other protocol. It simply acts as a router for abstract `ProxyStream` objects. It sits between the upstream CDN (fetching data via our Cloudflare-bypassing `rhttp` wrapper) and the local consumer (routing data directly to `media_kit` or the Downloader).

![Stream Proxy Architecture](/stream_proxy_architecture.jpg)

### The `ProxyStream` Contract
To support any streaming protocol, you simply extend the `ProxyStream` abstract class. The server only requires two things from a stream implementation:
1. `getLocalUrl(port)`: Returns the initial URL the video player should load.
2. `handleRequest(request, httpClient, port)`: Takes full control of any HTTP request routed to this stream's ID.

This means the proxy is entirely **plug-and-play**. Want to add DASH support tomorrow? Just create a `DashStream extends ProxyStream`, implement those two methods, and register it with the server!

---

## Registering a Stream

Before playback, the consumer (e.g., `PlayerController`) registers a specific stream implementation with the `StreamServer`.

```dart
final server = ref.read(streamServerProvider);

// Plug-and-play: We instantiate and pass a specific ProxyStream implementation. 
// The server gives us back a local URL to feed to the video player.
final localhostUrl = await server.register(
  MyCustomStream(
    id: uniqueStreamId,
    upstreamUrl: upstreamUrl,
  )
);

player.open(Media(localhostUrl));
```

---

## Server Lifecycle & Auto-Shutdown

To prevent memory leaks and dangling ports, `StreamServer` manages its own lifecycle using a **5-minute inactivity timer**.

::: tip Seamless Resumption
This ephemeral design allows background downloads to resume upon app restart! The downloader simply re-registers the upstream URL as a `ProxyStream` and spins up a new proxy effortlessly.
:::

1. Every time a stream is **registered**, the timer resets.
2. Every time **any request** hits `handleRequest`, the timer resets.
3. If no requests hit the server for **5 minutes** (e.g., the video is paused for a long time), the server automatically shuts down, releasing the port and destroying all streams and their caches.

---

## Existing Implementations

See the dedicated documentation for our existing protocol implementations:
- [HLS Implementation](/systems/hls_implementation)
