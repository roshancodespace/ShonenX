# Common Developer Tasks

This guide provides concrete steps for common development tasks in ShonenX.

## Adding a New Feature

If you are adding a completely new domain (e.g., "Statistics"), scaffold it like this:

1. Create `lib/features/statistics/`.
2. Inside it, create `domain/`, `api/`, `providers/`, and `presentation/`.
3. Define your models in `domain/statistics_model.dart`.
4. Create the fetcher in `api/statistics_client.dart` (injecting `HTTP`).
5. Expose the data via `providers/statistics_provider.dart` using `AsyncNotifierProvider`.
6. Build your UI in `presentation/statistics_screen.dart`.
7. Finally, register the new screen in `lib/core/router/app_router.dart`.

## Modifying Remote Configuration

ShonenX uses a remote config JSON to feature-flag unstable extensions or override API keys.

1. Locate `lib/core/remote_config/models/remote_config.dart`.
2. Add your new field to the Freezed/JsonSerializable model.
3. Run `dart run build_runner build -d`.
4. The UI can now access this flag safely:
   ```dart
   final config = ref.watch(remoteConfigProvider);
   if (config.value?.enableMyNewFeature == true) {
     // ...
   }
   ```

## Adding a New Subtitle Metadata Client

If you want to add a new service to fetch Episode Metadata (like Tenrai or Jikan):

1. Go to `lib/features/episode_metadata/services/`.
2. Create `my_service_metadata_client.dart`.
3. Implement the `EpisodeMetadataProvider` interface (note: the interface is named "Provider" historically, but your implementation should be named `Client` or `Source`).
4. You must implement `resolveId()` (to match a global `UnifiedMedia` to your service's specific ID) and `fetchEpisodes()`.
5. Register it in the `episode_metadata_providers.dart` Riverpod list so the UI can cycle through it as a fallback.
