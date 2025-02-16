import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:shonenx/providers/selected_provider.dart';

AnimeProvider? getAnimeProvider(WidgetRef ref) {
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
