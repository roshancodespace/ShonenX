# Declarative Routing with GoRouter

Navigation in ShonenX is declarative and centralized, powered by **GoRouter**. 

While imperative navigation (`Navigator.push`) works fine for small apps, a multi-platform app with desktop window management, deep linking, and bottom navigation requires declarative routing:
1. **Deep Linking:** URLs from external intents (like `aniyomi://` links) need to map cleanly to specific screens.
2. **Desktop History:** Desktop platforms require predictable back-stack behavior.
3. **Decoupled Screens:** Screens do not need to import each other's classes just to navigate.

The entire navigation map is defined in [`lib/core/router/app_router.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/core/router/app_router.dart).

---

## Persistent Navigation Shell (`StatefulShellRoute`)

The main interface layout (the Bottom Navigation Bar) is driven by a `StatefulShellRoute.indexedStack`.

```
App Router
│
├── StatefulShellRoute (Persistent Shell with Bottom Navigation Bar)
│   ├── Branch 1: Home Tab Stack
│   ├── Branch 2: Discover Tab Stack
│   ├── Branch 3: Library Tab Stack
│   └── Branch 4: Downloads Tab Stack
│
└── Top-Level Routes (Fullscreen Overlays)
    ├── /player   (Video Player)
    └── /reader   (Manga Reader)
```

Each branch maintains its own independent navigation history in an `IndexedStack`. When a user switches between "Home" and "Library", both screens remain in memory with their scroll positions intact instead of rebuilding from scratch.

**Rule of thumb:**
- If a screen should keep the bottom navigation bar visible, add it as a child route inside the corresponding shell branch.
- If a screen is an immersive fullscreen experience (like the Video Player or Manga Reader), register it at the top-level route tree *outside* the shell so it takes over the entire window.

---

## Passing Data: The `extra` Parameter

GoRouter allows passing arguments via path parameters, query parameters, or the `extra` object.

### The Role of `extra`
`extra` allows passing an existing in-memory Dart object (such as a full `UnifiedMedia` model) directly to the target screen:

```dart
// Navigating from a media card
context.pushNamed('details', extra: mediaObject);
```

This provides an instant transition because the details screen already has the title, cover image, and metadata without waiting for a network fetch.

### Handling Deep Links Gracefully
When a user opens the app through a deep link or the app is cold-booted, **`extra` is null** because the object was never in memory.

Every screen accepting `extra` handles both paths cleanly:

```dart
GoRoute(
  path: '/details/:id',
  name: 'details',
  builder: (context, state) {
    // 1. Fast Path: Use the pre-fetched object if available
    final media = state.extra as UnifiedMedia?;
    
    // 2. Fallback Path: Read the route parameter for deep links & cold boots
    final mediaId = state.pathParameters['id']!;
    
    return DetailsScreen(
      initialMedia: media,
      mediaId: mediaId,
    );
  },
),
```

Inside `DetailsScreen`, if `initialMedia` is null, the screen triggers a provider call to load the media details using `mediaId`. If present, it renders immediately.

---

## Adding a New Route

When adding a new screen:

1. Create your widget in `lib/features/<feature>/presentation/<screen_name>.dart`.
2. Open `lib/core/router/app_router.dart`.
3. Register the route with a unique path and name:
   ```dart
   GoRoute(
     path: '/settings/security',
     name: 'security-settings',
     builder: (context, state) => const SecuritySettingsScreen(),
   ),
   ```
4. Navigate using named navigation:
   ```dart
   context.pushNamed('security-settings');
   ```
   *(Named navigation avoids hardcoded URL strings, ensuring route paths can be updated without breaking navigation calls across the UI).*
