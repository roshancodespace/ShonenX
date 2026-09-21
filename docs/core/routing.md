# Routing and Navigation

Navigation in ShonenX is declarative, powered by [GoRouter](https://pub.dev/packages/go_router). 

The entire route tree is defined in a single place: [`lib/core/router/app_router.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/core/router/app_router.dart).

## Adding a New Route

When you create a new screen (e.g., `lib/features/my_feature/presentation/my_screen.dart`), you must register it in `app_router.dart`.

```dart
GoRoute(
  path: '/my-screen',
  name: 'my-screen', // Names are used for safe, path-independent navigation
  builder: (context, state) => const MyScreen(),
),
```

## Shell Routes (The Navigation Bar)

The main application layout (the Bottom Navigation Bar) is driven by a `StatefulShellRoute`. This means the `home`, `discover`, `library`, and `downloads` tabs exist inside a persistent shell. 

If you want a new screen to appear *underneath* the bottom navigation bar (so the bar is still visible), it must be added to a `StatefulShellBranch`. If you want it to hide the navigation bar (like the Video Player or a Details screen), add it as a top-level `GoRoute` outside the shell.

## Passing Complex Arguments

GoRouter expects parameters to be Strings in the URL path or query params. However, we often need to pass complex objects (like a full `UnifiedMedia` instance) to avoid making redundant network calls.

We solve this using the `extra` parameter.

### 1. Simple ID Navigation
```dart
// Navigating
context.pushNamed('details', pathParameters: {'id': '123'});

// Reading
final id = state.pathParameters['id']!;
```

### 2. Complex Object Navigation
Because `extra` can be dropped when deep-linking or refreshing on Web/Desktop, you must gracefully handle both cases:

```dart
// Navigating with a pre-fetched media object
context.pushNamed('details', extra: myMediaObject);
```

In the Router definition:
```dart
GoRoute(
  path: '/details',
  name: 'details',
  builder: (context, state) {
    // 1. Try to get the complex object from `extra`
    final media = state.extra as UnifiedMedia?;
    
    // 2. If it's missing (e.g., deep link), the screen must know how to fetch it!
    return DetailsScreen(media: media, fallbackId: state.uri.queryParameters['id']);
  },
),
```

## Deep Linking

GoRouter automatically intercepts custom URI schemes (like `aniyomi://` or `cloudstream://`). These are defined in the OS-specific manifests and handled directly in `app_router.dart` redirects.
