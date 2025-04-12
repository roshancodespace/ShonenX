import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:shonenx/providers/selected_provider.dart';

/// Get the current anime provider based on the selected provider key
/// Returns null if the registry is not initialized or the provider is not found
AnimeProvider? getAnimeProvider(WidgetRef ref) {
  try {
    // Use the centralized provider for getting the current anime provider
    return ref.read(currentAnimeProviderProvider);
  } catch (e, stackTrace) {
    dev.log('Error getting anime provider: $e',
        name: 'getAnimeProvider', error: e, stackTrace: stackTrace);

    // Fallback to manual resolution if the provider fails
    // Read the selected provider state
    final selectedState = ref.read(selectedProviderKeyProvider);

    // Ensure the state is not null and not in a loading state
    if (selectedState.isLoading) return null;

    // Extract the selected provider key
    final selectedKey = selectedState.selectedProviderKey;

    // Retrieve the registry instance
    final registryState = ref.read(animeSourceRegistryProvider);

    // Get the provider corresponding to the selected key
    return registryState.registry.getProvider(selectedKey);
  }
}
