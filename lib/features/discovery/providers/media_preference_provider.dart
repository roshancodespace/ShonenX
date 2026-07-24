import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/source_engine/source_registry.dart';

const Object _sentinel = Object();

class MediaPreferenceState {
  final SourceInfo sourceInfo;
  final String? matchedMediaId;
  final String? matchedMediaTitle;
  final TrackerType? preferredTracker;
  final String? trackerMediaId;

  MediaPreferenceState({
    required this.sourceInfo,
    this.matchedMediaId,
    this.matchedMediaTitle,
    this.preferredTracker,
    this.trackerMediaId,
  });

  MediaPreferenceState copyWith({
    SourceInfo? sourceInfo,
    Object? matchedMediaId = _sentinel,
    Object? matchedMediaTitle = _sentinel,
    Object? preferredTracker = _sentinel,
    Object? trackerMediaId = _sentinel,
  }) {
    return MediaPreferenceState(
      sourceInfo: sourceInfo ?? this.sourceInfo,
      matchedMediaId: matchedMediaId == _sentinel
          ? this.matchedMediaId
          : matchedMediaId as String?,
      matchedMediaTitle: matchedMediaTitle == _sentinel
          ? this.matchedMediaTitle
          : matchedMediaTitle as String?,
      preferredTracker: preferredTracker == _sentinel
          ? this.preferredTracker
          : preferredTracker as TrackerType?,
      trackerMediaId: trackerMediaId == _sentinel
          ? this.trackerMediaId
          : trackerMediaId as String?,
    );
  }

  @Deprecated('Use matchedMediaId instead')
  String? get manualOverrideId => matchedMediaId;

  @Deprecated('Use matchedMediaTitle instead')
  String? get manualOverrideTitle => matchedMediaTitle;

  @Deprecated('Use preferredTracker instead')
  TrackerType? get preferredAiringTracker => preferredTracker;

  @Deprecated('Use trackerMediaId instead')
  String? get manualAiringTrackerId => trackerMediaId;
}

class MediaPreferenceNotifier extends AsyncNotifier<MediaPreferenceState> {
  late final MediaArgs args;
  late final _isar = ref.read(databaseProvider);
  late final _log = AppLogger.scope(
    MediaPreferenceNotifier,
  ).child(args.mediaTitle);

  MediaPreferenceNotifier(this.args);

  Future<MediaPreference> _migrateLegacyPreferences(
    MediaPreference pref,
  ) async {
    bool needsSave = false;

    if (pref.matchedMediaId == null && pref.manualOverrideId != null) {
      pref.matchedMediaId = pref.manualOverrideId;
      pref.manualOverrideId = null;
      needsSave = true;
    }

    if (pref.matchedMediaTitle == null && pref.manualOverrideTitle != null) {
      pref.matchedMediaTitle = pref.manualOverrideTitle;
      pref.manualOverrideTitle = null;
      needsSave = true;
    }

    if (pref.preferredTracker == null && pref.preferredAiringTracker != null) {
      pref.preferredTracker = pref.preferredAiringTracker;
      pref.preferredAiringTracker = null;
      needsSave = true;
    }

    if (pref.trackerMediaId == null && pref.manualAiringTrackerId != null) {
      pref.trackerMediaId = pref.manualAiringTrackerId;
      pref.manualAiringTrackerId = null;
      needsSave = true;
    }

    if (needsSave) {
      await _isar.writeTxn(() async => await _isar.mediaPreferences.put(pref));
      _log.i('Migrated legacy media preferences for "${pref.mediaTitle}"');
    }

    return pref;
  }

  @override
  Future<MediaPreferenceState> build() async {
    final log = _log.child('build');

    try {
      final rawPref = await _isar.mediaPreferences.getByMediaTitle(
        args.mediaTitle,
      );

      final savedPreference = rawPref == null
          ? null
          : await _migrateLegacyPreferences(rawPref);

      final availableSources = args.type == MediaType.ANIME
          ? await ref.watch(availableAnimeSourcesProvider.future)
          : await ref.watch(availableMangaSourcesProvider.future);

      if (availableSources.isEmpty) {
        throw StateError('no-sources');
      }

      final defaultSource = availableSources.first;

      final preferredName = savedPreference?.preferredSourceName;
      final preferredId = savedPreference?.preferredSourceId;
      final preferredType = savedPreference?.preferredSourceType;

      final sourceType = preferredType == null
          ? null
          : SourceType.values.firstWhereOrNull(
              (type) => type.name == preferredType,
            );

      final SourceInfo resolvedSource;
      if (args.sourceId != null) {
        resolvedSource =
            availableSources.firstWhereOrNull(
              (source) => source.id == args.sourceId,
            ) ??
            defaultSource;
      } else if (sourceType != null && preferredId != null) {
        resolvedSource =
            availableSources.firstWhereOrNull(
              (source) =>
                  source.id == preferredId && source.name == preferredName,
            ) ??
            defaultSource;
      } else {
        resolvedSource = defaultSource;
      }

      log.i('Resolved → ${resolvedSource.name} (${resolvedSource.id})');

      TrackerType? preferredTracker;
      if (savedPreference?.preferredTracker != null) {
        preferredTracker = TrackerType.tryFromId(
          savedPreference!.preferredTracker!,
        );
      }

      return MediaPreferenceState(
        sourceInfo: resolvedSource,
        matchedMediaId: savedPreference?.matchedMediaId,
        matchedMediaTitle: savedPreference?.matchedMediaTitle,
        preferredTracker: preferredTracker,
        trackerMediaId: savedPreference?.trackerMediaId,
      );
    } catch (e, st) {
      log.e('Build failed', e, st);
      rethrow;
    }
  }

  void updateSource(SourceInfo sourceInfo) async {
    final log = _log.child('updateSource');

    log.i('Switch → ${sourceInfo.name}');

    state = AsyncData(
      state.value!.copyWith(
        sourceInfo: sourceInfo,
        matchedMediaId: null,
        matchedMediaTitle: null,
      ),
    );

    await _saveToDb();
    log.s('Updated');
  }

  void setManualMatch(String matchedMediaId, String matchedMediaTitle) {
    final log = _log.child('setManualMatch');

    log.i('Match → $matchedMediaTitle ($matchedMediaId)');

    state = AsyncData(
      state.value!.copyWith(
        matchedMediaId: matchedMediaId,
        matchedMediaTitle: matchedMediaTitle,
      ),
    );

    _saveToDb();
  }

  @Deprecated('Use setManualMatch instead')
  void setManualOverrides(String matchedMediaId, String matchedMediaTitle) {
    setManualMatch(matchedMediaId, matchedMediaTitle);
  }

  Future<void> saveAutoMatch(
    String matchedMediaId,
    String matchedMediaTitle,
  ) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final existing = await _isar.mediaPreferences.getByMediaTitle(
        args.mediaTitle,
      );
      final pref =
          existing ?? (MediaPreference()..mediaTitle = args.mediaTitle);

      pref.preferredSourceId = currentState.sourceInfo.id;
      pref.preferredSourceName = currentState.sourceInfo.name;
      pref.preferredSourceType = currentState.sourceInfo.type.name;
      pref.matchedMediaId = matchedMediaId;
      pref.matchedMediaTitle = matchedMediaTitle;

      await _isar.writeTxn(() async => await _isar.mediaPreferences.put(pref));

      state = AsyncData(
        currentState.copyWith(
          matchedMediaId: matchedMediaId,
          matchedMediaTitle: matchedMediaTitle,
        ),
      );
    } catch (e, st) {
      _log.e('Failed to save auto match', e, st);
    }
  }

  void setPreferredTracker(TrackerType trackerType) {
    final log = _log.child('setPreferredTracker');
    log.i('Tracker → ${trackerType.displayName}');

    state = AsyncData(state.value!.copyWith(preferredTracker: trackerType));

    _saveToDb();
  }

  @Deprecated('Use setPreferredTracker instead')
  void setPreferredAiringTracker(TrackerType trackerType) {
    setPreferredTracker(trackerType);
  }

  void updatePrefs(
    SourceInfo sourceInfo,
    String matchedMediaId,
    String matchedMediaTitle,
  ) {
    state = AsyncData(
      state.value!.copyWith(
        sourceInfo: sourceInfo,
        matchedMediaId: matchedMediaId,
        matchedMediaTitle: matchedMediaTitle,
      ),
    );
    _saveToDb();
  }

  Future<void> _saveToDb() async {
    final log = _log.child('_saveToDb');

    final currentState = state.value;
    if (currentState == null) return;

    try {
      final pref = MediaPreference()
        ..mediaTitle = args.mediaTitle
        ..preferredSourceId = currentState.sourceInfo.id
        ..preferredSourceName = currentState.sourceInfo.name
        ..preferredSourceType = currentState.sourceInfo.type.name
        ..matchedMediaId = currentState.matchedMediaId
        ..matchedMediaTitle = currentState.matchedMediaTitle
        ..preferredTracker = currentState.preferredTracker?.id
        ..trackerMediaId = currentState.trackerMediaId;

      await _isar.writeTxn(() async => await _isar.mediaPreferences.put(pref));

      log.s('Saved');
    } catch (e, st) {
      log.e('Save failed', e, st);
    }
  }

  Future<void> clearPreference() async {
    try {
      await _isar.writeTxn(
        () async =>
            await _isar.mediaPreferences.deleteByMediaTitle(args.mediaTitle),
      );

      state = const AsyncLoading();
      state = await AsyncValue.guard(() => build());
    } catch (e, st) {
      _log.e('Failed to clear overrides', e, st);
    }
  }

  Future<void> setTrackerMediaId(String trackerMediaId) async {
    try {
      final existing = await _isar.mediaPreferences.getByMediaTitle(
        args.mediaTitle,
      );
      final newPref =
          existing ?? (MediaPreference()..mediaTitle = args.mediaTitle);

      newPref.trackerMediaId = trackerMediaId;
      // Inherit source state
      newPref.preferredSourceId = state.value!.sourceInfo.id;
      newPref.preferredSourceName = state.value!.sourceInfo.name;
      newPref.preferredSourceType = state.value!.sourceInfo.type.name;

      await _isar.writeTxn(() async {
        await _isar.mediaPreferences.put(newPref);
      });

      state = AsyncData(state.value!.copyWith(trackerMediaId: trackerMediaId));
    } catch (e, st) {
      _log.e('Failed to set tracker media id', e, st);
    }
  }

  @Deprecated('Use setTrackerMediaId instead')
  Future<void> setManualAiringTrackerId(String trackerMediaId) async {
    return setTrackerMediaId(trackerMediaId);
  }
}

final mediaPreferenceProvider =
    AsyncNotifierProvider.family<
      MediaPreferenceNotifier,
      MediaPreferenceState,
      MediaArgs
    >(MediaPreferenceNotifier.new, name: 'mediaPreferenceProvider');
