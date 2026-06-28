import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

enum MetadataMode { tracker, source }

class DiscoveryPrefs {
  final MetadataMode mode;
  final List<String> activeSources;
  final String? metadataTrackerId;

  const DiscoveryPrefs({
    this.mode = MetadataMode.tracker,
    this.activeSources = const [],
    this.metadataTrackerId,
  });

  DiscoveryPrefs copyWith({
    MetadataMode? mode,
    List<String>? activeSources,
    String? metadataTrackerId,
  }) {
    return DiscoveryPrefs(
      mode: mode ?? this.mode,
      activeSources: activeSources ?? this.activeSources,
      metadataTrackerId: metadataTrackerId ?? this.metadataTrackerId,
    );
  }
}

class DiscoveryPrefsNotifier extends Notifier<DiscoveryPrefs> {
  static const _modeKey = 'discovery_mode';
  static const _activeSourcesKey = 'discovery_active_sources';
  static const _metadataTrackerKey = 'discovery_metadata_tracker_id';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  DiscoveryPrefs build() {
    final modeStr = _storage.getString(_modeKey);
    final mode = MetadataMode.values.firstWhere(
      (e) => e.name == modeStr,
      orElse: () => MetadataMode.tracker,
    );
    final activeSources = _storage.getStringList(_activeSourcesKey) ?? [];
    final metadataTrackerId = _storage.getString(_metadataTrackerKey);

    return DiscoveryPrefs(
      mode: mode,
      activeSources: activeSources,
      metadataTrackerId: metadataTrackerId,
    );
  }

  void setMode(MetadataMode mode) {
    _storage.setString(_modeKey, mode.name);
    state = state.copyWith(mode: mode);
  }

  void setActiveSources(List<String> sources) {
    _storage.setStringList(_activeSourcesKey, sources);
    state = state.copyWith(activeSources: sources);
  }

  void toggleSource(String sourceId) {
    final sources = List<String>.from(state.activeSources);
    if (sources.contains(sourceId)) {
      sources.remove(sourceId);
    } else {
      sources.add(sourceId);
    }
    setActiveSources(sources);
  }

  void setMetadataTrackerId(String? trackerId) {
    if (trackerId == null) {
      _storage.remove(_metadataTrackerKey);
    } else {
      _storage.setString(_metadataTrackerKey, trackerId);
    }
    state = DiscoveryPrefs(
      mode: state.mode,
      activeSources: state.activeSources,
      metadataTrackerId: trackerId,
    );
  }
}

final discoveryPrefsProvider =
    NotifierProvider<DiscoveryPrefsNotifier, DiscoveryPrefs>(
      DiscoveryPrefsNotifier.new,
      name: 'discoveryPrefsProvider',
    );
