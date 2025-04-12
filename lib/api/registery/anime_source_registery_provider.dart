import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/sources/anime/animekai.dart';
import 'package:shonenx/api/sources/anime/animepahe.dart';
import 'package:shonenx/api/sources/anime/aniwatch/aniwatch.dart';
import 'package:shonenx/api/sources/anime/aniwatch/hianime.dart';
import 'package:shonenx/api/registery/anime_source_registery.dart';
import 'package:shonenx/api/sources/anime/anime_provider.dart';
import 'package:shonenx/api/sources/anime/aniwatch/kaido.dart';
import 'package:shonenx/providers/selected_provider.dart';

/// State class for the anime source registry
class AnimeSourceRegistryState {
  final AnimeSourceRegistery registry;
  final bool isInitializing;
  final String? error;
  final String? customApiUrl;

  const AnimeSourceRegistryState({
    required this.registry,
    this.isInitializing = false,
    this.error,
    this.customApiUrl,
  });

  AnimeSourceRegistryState copyWith({
    AnimeSourceRegistery? registry,
    bool? isInitializing,
    String? error,
    String? customApiUrl,
  }) {
    return AnimeSourceRegistryState(
      registry: registry ?? this.registry,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error, // Allow null to clear error
      customApiUrl: customApiUrl ?? this.customApiUrl,
    );
  }
}

/// Notifier for the anime source registry
class AnimeSourceRegistryNotifier
    extends StateNotifier<AnimeSourceRegistryState> {
  // Flag to prevent multiple initializations
  bool _isInitializing = false;

  AnimeSourceRegistryNotifier()
      : super(AnimeSourceRegistryState(registry: AnimeSourceRegistery())) {
    dev.log('AnimeSourceRegistryNotifier created', name: 'AnimeSourceRegistry');
  }

  /// Initialize the registry with the given API URL
  /// This should be called during app startup
  Future<void> initialize(String? apiUrl) async {
    // Prevent multiple initializations
    if (_isInitializing) {
      dev.log('Registry initialization already in progress',
          name: 'AnimeSourceRegistry');
      return;
    }

    try {
      _isInitializing = true;
      state = state.copyWith(isInitializing: true, error: null);

      // Set registry status to initializing
      state.registry.setStatus(RegistryStatus.initializing);

      // Clear any existing providers
      state.registry.clear();

      // Register all providers
      final providers = [
        {"key": "hianime", "provider": HiAnimeProvider(customApiUrl: apiUrl)},
        {"key": "aniwatch", "provider": AniwatchProvider(customApiUrl: apiUrl)},
        {"key": "kaido", "provider": KaidoProvider(customApiUrl: apiUrl)},
        {"key": "animekai", "provider": AnimekaiProvider(customApiUrl: apiUrl)},
        {
          "key": "animepahe",
          "provider": AnimePaheProvider(customApiUrl: apiUrl)
        },
      ];

      // Register each provider and track failures
      final failedProviders = <String>[];
      for (final providerData in providers) {
        final key = providerData["key"] as String;
        final provider = providerData["provider"] as AnimeProvider;

        final success = state.registry.registerProvider(key, provider);
        if (!success) {
          failedProviders.add(key);
        }
      }

      // Check if any providers failed to register
      if (failedProviders.isNotEmpty) {
        final errorMsg =
            'Failed to register providers: ${failedProviders.join(', ')}';
        state.registry.setStatus(RegistryStatus.error, errorMsg);
        state = state.copyWith(
          isInitializing: false,
          error: errorMsg,
          customApiUrl: apiUrl,
        );
        return;
      }

      // Set registry status to initialized
      state.registry.setStatus(RegistryStatus.initialized);
      state = state.copyWith(
        isInitializing: false,
        error: null,
        customApiUrl: apiUrl,
      );

      dev.log(
          'Registry initialized with ${state.registry.providerCount} providers',
          name: 'AnimeSourceRegistry');
    } catch (e, stackTrace) {
      final errorMsg = 'Error initializing registry: $e';
      state.registry.setStatus(RegistryStatus.error, errorMsg);
      state = state.copyWith(
        isInitializing: false,
        error: errorMsg,
      );
      dev.log(errorMsg,
          name: 'AnimeSourceRegistry', error: e, stackTrace: stackTrace);
    } finally {
      _isInitializing = false;
    }
  }

  /// Update the API URL for all providers
  Future<void> updateApiUrl(String newApiUrl) async {
    dev.log('Updating API URL to: $newApiUrl', name: 'AnimeSourceRegistry');
    await initialize(newApiUrl);
  }

  /// Reset the API URL to the default
  Future<void> resetApiUrl() async {
    dev.log('Resetting API URL to default', name: 'AnimeSourceRegistry');
    await initialize(null);
  }

  /// Get a provider by key
  AnimeProvider? getProvider(String key) {
    return state.registry.getProvider(key);
  }

  /// Get all provider keys
  List<String> get allProviderKeys => state.registry.allProviderKeys;

  /// Get all providers
  List<AnimeProvider> get allProviders => state.registry.allProviders;
}

/// Provider for the anime source registry
final animeSourceRegistryProvider = StateNotifierProvider<
    AnimeSourceRegistryNotifier,
    AnimeSourceRegistryState>((ref) => AnimeSourceRegistryNotifier());

/// Provider for the current anime provider based on the selected provider key
final currentAnimeProviderProvider = Provider<AnimeProvider?>((ref) {
  final registryState = ref.watch(animeSourceRegistryProvider);
  final selectedState = ref.watch(selectedProviderKeyProvider);

  // If the registry is not initialized or the selected provider is loading, return null
  if (!registryState.registry.isInitialized || selectedState.isLoading) {
    return null;
  }

  final selectedKey = selectedState.selectedProviderKey;
  return registryState.registry.getProvider(selectedKey);
});

/// Provider that indicates whether the anime source registry is ready to use
final isAnimeSourceRegistryReadyProvider = Provider<bool>((ref) {
  final registryState = ref.watch(animeSourceRegistryProvider);
  return registryState.registry.isInitialized && !registryState.isInitializing;
});
