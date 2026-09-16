# Data Flow & State Management

ShonenX embraces a unidirectional data flow powered strictly by Riverpod.

## State Management

State is initialized and exposed via `Notifier` and `AsyncNotifier` implementations inside a feature's `providers/` directory.

- **UI Consumption:** `ConsumerWidget` and `ConsumerStatefulWidget` are used to bind to providers. The presentation layer never instantiates engine classes directly.
- **Dependency Injection:** Providers are used to inject shared dependencies (e.g., `sharedPreferencesProvider`, `databaseProvider`) into feature-specific engines.

### Example Flow

1. **User Action:** The user taps a "Refresh Library" button.
2. **Provider Invocation:** The UI calls `ref.read(libraryProvider.notifier).refresh()`.
3. **Engine Execution:** The `LibraryNotifier` delegates the complex synchronization logic to `LibraryEngine`.
4. **State Mutation:** The `LibraryEngine` completes the fetch and returns the data. The `LibraryNotifier` updates its state (`state = AsyncData(newData)`).
5. **UI Rebuild:** The UI, watching `libraryProvider`, automatically rebuilds with the new data.

## Persistence

[Isar](https://isar.dev/) acts as the local source of truth for caching, library entries, and user history.

- Models that require persistence are annotated with `@collection`.
- When models are modified, you must regenerate the Isar schemas using `dart run build_runner build -d`.
- Database initialization occurs in [`app_init.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/app_init.dart), which opens the instance and executes any necessary data migrations before the UI mounts.
