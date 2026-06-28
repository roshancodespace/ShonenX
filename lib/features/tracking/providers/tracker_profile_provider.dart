import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

final trackerProfileProvider =
    NotifierProvider<TrackerProfileProvider, Map<TrackerType, TrackerProfile>>(
      retry: (retryCount, error) => null,
      TrackerProfileProvider.new,
    );

class TrackerProfileProvider
    extends Notifier<Map<TrackerType, TrackerProfile>> {
  static const _profileDataKey = 'tracker_profiles_data';

  @override
  Map<TrackerType, TrackerProfile> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString(_profileDataKey);

    if (jsonString != null) {
      try {
        final decoded = json.decode(jsonString) as Map<String, dynamic>;
        return decoded.map(
          (key, value) =>
              MapEntry(TrackerType.fromId(key), TrackerProfile.fromMap(value)),
        );
      } catch (_) {}
    }

    return {};
  }

  void saveProfile(TrackerType trackerType, TrackerProfile profile) {
    final updatedMap = Map<TrackerType, TrackerProfile>.from(state);
    updatedMap[trackerType] = profile;

    state = updatedMap;

    final jsonMap = updatedMap.map(
      (key, value) => MapEntry(key.id, value.toMap()),
    );
    ref
        .read(sharedPreferencesProvider)
        .setString(_profileDataKey, json.encode(jsonMap));
  }

  void removeProfile(TrackerType trackerType) {
    final updatedMap = Map<TrackerType, TrackerProfile>.from(state);
    updatedMap.remove(trackerType);

    state = updatedMap;

    final jsonMap = updatedMap.map(
      (key, value) => MapEntry(key.id, value.toMap()),
    );
    ref
        .read(sharedPreferencesProvider)
        .setString(_profileDataKey, json.encode(jsonMap));
  }
}
