import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:shonenx/providers/selected_provider.dart';
import 'package:shonenx/providers/watch_providers.dart';

AnimeProvider? getAnimeProvider(WidgetRef ref) {
  try {
    // Use the centralized provider instead of manually resolving dependencies
    return ref.read(currentAnimeProviderProvider);
  } catch (e) {
    // Fallback to the old method if the provider is not available in the current scope
    // Read the selected provider state
    final selectedState = ref.read(selectedProviderKeyProvider);

    // Ensure the state is not null and not in a loading state
    if (selectedState.isLoading) return null;

    // Extract the selected provider key
    final selectedKey = selectedState.selectedProviderKey;

    // Retrieve the registry instance
    final registry = ref.read(animeSourceRegistryProvider);

    // Get the provider corresponding to the selected key
    return registry.getProvider(selectedKey);
  }
}
