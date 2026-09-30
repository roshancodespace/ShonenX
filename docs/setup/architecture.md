# Architecture Walkthrough

When an application grows into a multi-platform client with video playback, extension bridges, and tracker synchronization, architectural discipline becomes essential. 

Mixing network calls inside widget build methods or scattering mutable global state across files creates code that is fragile, hard to test, and painful to maintain.

In ShonenX, we follow a **Layered Feature-First Architecture**. Here is how the project is organized, the layer rules we enforce, and how the app bootstraps its core systems.

---

## Directory Organization

```
lib/
├── core/            # Infrastructure & plumbing (Zero UI features)
├── features/        # Feature slices (player, library, tracking, downloads)
│   └── <feature>/
│       ├── domain/        # Pure Dart models & interfaces
│       ├── engine/        # Repositories, fetchers, and heavy logic
│       ├── providers/     # Riverpod state managers (Bridge to UI)
│       └── presentation/  # Flutter widgets & screens
├── shared/          # Reusable cross-feature models & UI components
└── source_engine/   # Bridge orchestrator and data normalization
```

---

## Layer Responsibilities & Rules

Data and control flow in a single direction through strict boundaries:

```
[ Presentation (Widgets) ]
            │ (ref.watch / ref.read)
            ▼
[ State (Riverpod Providers) ]
            │ (invokes methods)
            ▼
[ Logic (Feature Engines / Repositories) ]
            │ (reads & writes)
            ▼
[ Infrastructure (Isar DB / Rust rhttp + DoH) ]
```

### 1. Presentation Layer (Widgets)
Flutter widgets in `presentation/` focus purely on rendering UI and handling user interaction:
- Widgets consume state by watching Riverpod providers (`ref.watch()`).
- Widgets trigger user actions by calling methods on provider notifiers (`ref.read().myAction()`).
- Widgets **never** instantiate database connections, API clients, or player engines directly.

### 2. Providers Layer (State Management)
Providers in `providers/` are the dedicated bridge between business logic and the screen:
- Expose state using `FutureProvider`, `AsyncNotifierProvider`, or `NotifierProvider`.
- Orchestrate background tasks and update local state reactively.
- Handle dependency injection for repositories and services.

### 3. Features Are Isolated
Code in `lib/features/library/` should not directly import internal widgets or private helpers from `lib/features/discovery/`. 

If a widget (like `MediaCard` or `AnimeCarousel`) or data model (`UnifiedMedia`) is needed across multiple features, it belongs in **`lib/shared/`**. Keeping features decoupled prevents circular dependencies and makes refactoring much simpler.

---

## Application Initialization: The Startup Chain

When ShonenX launches, the entry point is `lib/main.dart`, but the initialization sequence is managed by [`lib/app_init.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/app_init.dart). 

Native subsystems must be initialized in a specific sequence:

1. **`SharedPreferences.getInstance()`** — Loads persistent local settings into memory.
2. **`DohResolver.instance.init(prefs)`** — Reads the user's saved DoH provider (`cloudflare`, `google`, or `system`) so the dynamic DNS resolver is warmed up before any network socket is opened.
3. **`Rhttp.init()`** — Loads the native Rust dynamic library (`librhttp.so` / `.dll` / `.dylib`) via FFI.
4. **`WindowManager` configuration** — On desktop platforms (Linux/Windows/macOS), sets initial window dimensions, minimum sizes, and titlebar styling.
5. **`MediaKit.ensureInitialized()`** — Prepares native `libmpv` video and audio engine hooks.
6. **`Isar.open(...)`** — Opens the offline database collections (watch history, cache entries, download tasks).
7. **`setupBridge()`** — Lazily spins up the embedded QuickJS runtime for third-party extensions.
8. **`runApp(...)`** — Mounts the root `ProviderScope` and launches the Flutter widget tree.

### Why DoH Initializes Before Rhttp
`Rhttp` accepts dynamic DNS resolution callbacks (`rhttp.DnsSettings.dynamic(...)`). When ShonenX starts, `DohResolver` loads the user's saved DNS provider from `SharedPreferences` *before* the network client pool is created. This ensures the very first request made by the app uses encrypted DNS-over-HTTPS.

---

## The Extension Bridge (`packages/anymex_extension_bridge`)

Notice that `anymex_extension_bridge` lives under `packages/` rather than `lib/`. 

It operates as an independent local Dart package that runs an embedded Javascript engine (QuickJS) and native bindings to execute scrapers from Mangayomi, Cloudstream, and Aniyomi. 

Keeping it decoupled in `packages/` keeps the core application clean: ShonenX doesn't need to know the internal details of third-party scraper formats—it simply receives normalized `UnifiedMedia` and `UnifiedChapter` objects in return.
