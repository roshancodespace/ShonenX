import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_auth_mode.dart';

class TrackingPrefsState {
  final bool isIncognito;
  final Map<TrackerType, bool> enabledTrackers;
  final TrackerType primaryTracker;
  final bool autoTrackPrimary;
  final double syncThreshold;
  final Map<TrackerType, TrackerCredentials> customCredentials;
  final TrackerAuthMode authMode;

  TrackingPrefsState({
    this.isIncognito = false,
    this.enabledTrackers = const {},
    this.primaryTracker = TrackerType.local,
    this.autoTrackPrimary = false,
    this.syncThreshold = 0.8,
    this.customCredentials = const {},
    this.authMode = TrackerAuthMode.auto,
  });

  TrackingPrefsState copyWith({
    bool? isIncognito,
    Map<TrackerType, bool>? enabledTrackers,
    TrackerType? primaryTracker,
    bool? autoTrackPrimary,
    double? syncThreshold,
    Map<TrackerType, TrackerCredentials>? customCredentials,
    TrackerAuthMode? authMode,
  }) {
    return TrackingPrefsState(
      isIncognito: isIncognito ?? this.isIncognito,
      enabledTrackers: enabledTrackers ?? this.enabledTrackers,
      primaryTracker: primaryTracker ?? this.primaryTracker,
      autoTrackPrimary: autoTrackPrimary ?? this.autoTrackPrimary,
      syncThreshold: syncThreshold ?? this.syncThreshold,
      customCredentials: customCredentials ?? this.customCredentials,
      authMode: authMode ?? this.authMode,
    );
  }

  bool isTrackerEnabled(TrackerType trackerType) {
    if (trackerType == TrackerType.local) return true;
    return enabledTrackers[trackerType] ?? false;
  }

  Map<String, dynamic> toMap() {
    return {
      'isIncognito': isIncognito,
      'enabledTrackers': enabledTrackers.map(
        (key, value) => MapEntry(key.id, value),
      ),
      'primaryTracker': primaryTracker.id,
      'autoTrackPrimary': autoTrackPrimary,
      'syncThreshold': syncThreshold,
      'customCredentials': customCredentials.map(
        (key, value) => MapEntry(key.id, value.toMap()),
      ),
      'authMode': authMode.name,
    };
  }

  factory TrackingPrefsState.fromMap(Map<String, dynamic> map) {
    return TrackingPrefsState(
      isIncognito: map['isIncognito'] ?? false,
      enabledTrackers:
          (map['enabledTrackers'] as Map?)?.map(
            (key, value) => MapEntry(
              TrackerType.values.firstWhere(
                (e) => e.id == key,
                orElse: () => TrackerType.anilist,
              ),
              value as bool,
            ),
          ) ??
          {},
      primaryTracker: TrackerType.values.firstWhere(
        (e) => e.id == map['primaryTracker'],
        orElse: () => TrackerType.anilist,
      ),
      autoTrackPrimary: map['autoTrackPrimary'] ?? false,
      syncThreshold: (map['syncThreshold'] as num?)?.toDouble() ?? 0.8,
      customCredentials:
          (map['customCredentials'] as Map?)?.map(
            (key, value) => MapEntry(
              TrackerType.values.firstWhere(
                (e) => e.id == key,
                orElse: () => TrackerType.anilist,
              ),
              TrackerCredentials.fromMap(
                Map<String, dynamic>.from(value as Map),
              ),
            ),
          ) ??
          {},
      authMode: TrackerAuthMode.values.firstWhere(
        (e) => e.name == map['authMode'],
        orElse: () => TrackerAuthMode.auto,
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TrackingPrefsState.fromJson(String source) =>
      TrackingPrefsState.fromMap(jsonDecode(source));
}

class TrackingPrefsNotifier extends Notifier<TrackingPrefsState> {
  static const _trackingPrefsKey = 'app_tracking_prefs';

  @override
  TrackingPrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final jsonString = prefs.getString(_trackingPrefsKey);

    TrackingPrefsState stateVal;
    if (jsonString != null) {
      try {
        stateVal = TrackingPrefsState.fromJson(jsonString);
      } catch (e) {
        stateVal = TrackingPrefsState(
          enabledTrackers: {
            TrackerType.anilist: true,
            TrackerType.myanimelist: true,
            TrackerType.kitsu: true,
          },
        );
      }
    } else {
      stateVal = TrackingPrefsState(
        enabledTrackers: {
          TrackerType.anilist: true,
          TrackerType.myanimelist: true,
          TrackerType.kitsu: true,
        },
      );
    }

    return stateVal;
  }

  void setPrimaryTracker(TrackerType type) {
    state = state.copyWith(primaryTracker: type);
    _saveDb();
  }

  void toggleIncognito() {
    state = state.copyWith(isIncognito: !state.isIncognito);
    _saveDb();
  }

  void toggleAutoTrackPrimary() {
    state = state.copyWith(autoTrackPrimary: !state.autoTrackPrimary);
    _saveDb();
  }

  void updateSyncThreshold(double threshold) {
    state = state.copyWith(syncThreshold: threshold);
    _saveDb();
  }

  void toggleTracker(TrackerType type, bool isEnabled) {
    final updatedMap = Map<TrackerType, bool>.from(state.enabledTrackers);
    updatedMap[type] = isEnabled;

    if (isEnabled) {
      setPrimaryTracker(type);
    } else {
      setPrimaryTracker(TrackerType.local);
    }

    state = state.copyWith(enabledTrackers: updatedMap);
    _saveDb();
  }

  void setCustomCredentials(
    TrackerType type,
    String clientId,
    String clientSecret,
  ) {
    final cleanId = clientId.trim();
    final cleanSecret = clientSecret.trim();

    if (cleanId.isEmpty && cleanSecret.isEmpty) {
      clearCustomCredentials(type);
      return;
    }

    final updatedMap = Map<TrackerType, TrackerCredentials>.from(
      state.customCredentials,
    );
    updatedMap[type] = TrackerCredentials(
      clientId: cleanId,
      clientSecret: cleanSecret,
    );
    state = state.copyWith(customCredentials: updatedMap);
    _saveDb();
  }

  void clearCustomCredentials(TrackerType type) {
    final updatedMap = Map<TrackerType, TrackerCredentials>.from(
      state.customCredentials,
    );
    updatedMap.remove(type);
    state = state.copyWith(customCredentials: updatedMap);
    _saveDb();
  }

  void setAuthMode(TrackerAuthMode mode) {
    state = state.copyWith(authMode: mode);
    _saveDb();
  }

  void _saveDb() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_trackingPrefsKey, state.toJson());
  }
}

final trackingPrefsProvider =
    NotifierProvider<TrackingPrefsNotifier, TrackingPrefsState>(
      TrackingPrefsNotifier.new,
    );
