import 'dart:developer' as dev;
import 'package:shonenx/api/sources/anime/anime_provider.dart';

/// Enum representing the initialization status of the registry
enum RegistryStatus { uninitialized, initializing, initialized, error }

/// A registry for anime source providers with improved error handling and management
class AnimeSourceRegistery {
  /// Map of provider keys to provider instances
  final Map<String, AnimeProvider> _providers = {};

  /// Current status of the registry
  RegistryStatus _status = RegistryStatus.uninitialized;

  /// Error message if initialization failed
  String? _errorMessage;

  /// Get the current status of the registry
  RegistryStatus get status => _status;

  /// Get the error message if initialization failed
  String? get errorMessage => _errorMessage;

  /// Check if the registry is initialized
  bool get isInitialized => _status == RegistryStatus.initialized;

  /// Register a provider by a key
  /// Returns true if registration was successful, false otherwise
  bool registerProvider(String key, AnimeProvider provider) {
    try {
      if (key.isEmpty) {
        dev.log('Cannot register provider with empty key',
            name: 'AnimeSourceRegistry');
        return false;
      }

      if (_providers.containsKey(key)) {
        dev.log('Provider with key $key already exists, replacing',
            name: 'AnimeSourceRegistry');
      }

      _providers[key] = provider;
      dev.log('Registered provider: $key', name: 'AnimeSourceRegistry');
      return true;
    } catch (e, stackTrace) {
      dev.log('Error registering provider $key: $e',
          name: 'AnimeSourceRegistry', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Retrieve a provider by key
  /// Returns null if the provider doesn't exist
  AnimeProvider? getProvider(String key) {
    if (!isInitialized) {
      dev.log('Registry not initialized, cannot get provider: $key',
          name: 'AnimeSourceRegistry');
      return null;
    }

    final provider = _providers[key];
    if (provider == null) {
      dev.log('Provider not found for key: $key', name: 'AnimeSourceRegistry');
    }
    return provider;
  }

  /// List all registered providers
  List<AnimeProvider> get allProviders => _providers.values.toList();

  /// Get all provider keys
  List<String> get allProviderKeys => _providers.keys.toList();

  /// Check if a provider exists
  bool hasProvider(String key) => _providers.containsKey(key);

  /// Get the number of registered providers
  int get providerCount => _providers.length;

  /// Clear all providers
  void clear() {
    _providers.clear();
    dev.log('Cleared all providers', name: 'AnimeSourceRegistry');
  }

  /// Set the registry status
  void setStatus(RegistryStatus status, [String? errorMessage]) {
    _status = status;
    _errorMessage = errorMessage;
    dev.log('Registry status changed to: $_status',
        name: 'AnimeSourceRegistry');
    if (errorMessage != null) {
      dev.log('Registry error: $errorMessage', name: 'AnimeSourceRegistry');
    }
  }
}
