import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/database_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/domain/media_preference.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

const Object _sentinel = Object();

class MediaPreferenceState {
  final SourceInfo sourceInfo;
  final String? manualOverrideId;
  final String? manualOverrideTitle;
  final TrackerType? preferredAiringTracker;
  final String? manualAiringTrackerId;

  MediaPreferenceState({
    required this.sourceInfo,
    this.manualOverrideId,
    this.manualOverrideTitle,
    this.preferredAiringTracker,
    this.manualAiringTrackerId,
  });

  MediaPreferenceState copyWith({
    SourceInfo? sourceInfo,
    Object? manualOverrideId = _sentinel,
    Object? manualOverrideTitle = _sentinel,
    Object? preferredAiringTracker = _sentinel,
    Object? manualAiringTrackerId = _sentinel,
  }) {
    return MediaPreferenceState(
      sourceInfo: sourceInfo ?? this.sourceInfo,
      manualOverrideId: manualOverrideId == _sentinel
          ? this.manualOverrideId
          : manualOverrideId as String?,
      manualOverrideTitle: manualOverrideTitle == _sentinel
          ? this.manualOverrideTitle
          : manualOverrideTitle as String?,
      preferredAiringTracker: preferredAiringTracker == _sentinel
          ? this.preferredAiringTracker
          : preferredAiringTracker as TrackerType?,
      manualAiringTrackerId: manualAiringTrackerId == _sentinel
          ? this.manualAiringTrackerId
          : manualAiringTrackerId as String?,
    );
  }
}

class MediaPreferenceNotifier extends AsyncNotifier<MediaPreferenceState> {
  late final MatchArgs args;
  late final _isar = ref.read(databaseProvider);
  late final _log = AppLogger.scope(
    MediaPreferenceNotifier,
  ).child(args.mediaTitle);

  MediaPreferenceNotifier(this.args);

  @override
  Future<MediaPreferenceState> build() async {
    final log = _log.child('build');

    try {
      final savedPref = await _isar.mediaPreferences.getByMediaTitle(
        args.mediaTitle,
      );

      final availableSourcesInfo = args.type == MediaType.ANIME
          ? await ref.watch(availableAnimeSourcesProvider.future)
          : await ref.watch(availableMangaSourcesProvider.future);

      if (availableSourcesInfo.isEmpty) {
        throw StateError('no-sources');
      }

      final globalDefaultSourceInfo = availableSourcesInfo.first;

      final preferredName = savedPref?.preferredSourceName;
      final preferredId = savedPref?.preferredSourceId;
      final preferredType = savedPref?.preferredSourceType;

      final type = preferredType == null
          ? null
          : SourceType.values.firstWhereOrNull((s) => s.name == preferredType);

      final SourceInfo resolvedSource;
      if (type != null && preferredId != null) {
        resolvedSource =
            availableSourcesInfo.firstWhereOrNull(
              (s) => s.id == preferredId && s.name == preferredName,
            ) ??
            globalDefaultSourceInfo;
      } else if (args.sourceId != null) {
        resolvedSource =
            availableSourcesInfo.firstWhereOrNull(
              (s) => s.id == args.sourceId,
            ) ??
            globalDefaultSourceInfo;
      } else {
        resolvedSource = globalDefaultSourceInfo;
      }

      log.i('Resolved → ${resolvedSource.name} (${resolvedSource.id})');

      TrackerType? tracker;
      if (savedPref?.preferredAiringTracker != null) {
        tracker = TrackerType.tryFromId(savedPref!.preferredAiringTracker!);
      }

      return MediaPreferenceState(
        sourceInfo: resolvedSource,
        manualOverrideId: savedPref?.manualOverrideId,
        manualOverrideTitle: savedPref?.manualOverrideTitle,
        preferredAiringTracker: tracker,
        manualAiringTrackerId: savedPref?.manualAiringTrackerId,
      );
    } catch (e, st) {
      log.e('Build failed', e, st);
      rethrow;
    }
  }

  void updateSource(SourceInfo newSourceInfo) async {
    final log = _log.child('updateSource');

    log.i('Switch → ${newSourceInfo.name}');

    state = AsyncData(
      state.value!.copyWith(
        sourceInfo: newSourceInfo,
        manualOverrideId: null,
        manualOverrideTitle: null,
      ),
    );

    await _saveToDb();
    log.s('Updated');
  }

  void setManualOverrides(String overrideId, String overrideTitle) {
    final log = _log.child('setManualOverrides');

    log.i('Override → $overrideTitle ($overrideId)');

    state = AsyncData(
      state.value!.copyWith(
        manualOverrideId: overrideId,
        manualOverrideTitle: overrideTitle,
      ),
    );

    _saveToDb();
  }

  Future<void> saveAutoMatch(String matchedId, String matchedTitle) async {
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
      pref.manualOverrideId = matchedId;
      pref.manualOverrideTitle = matchedTitle;

      await _isar.writeTxn(() async => await _isar.mediaPreferences.put(pref));

      state = AsyncData(
        currentState.copyWith(
          manualOverrideId: matchedId,
          manualOverrideTitle: matchedTitle,
        ),
      );
    } catch (e, st) {
      _log.e('Failed to save auto match', e, st);
    }
  }

  Future<void> saveWatchPreference({
    required SourceInfo sourceInfo,
    required String mediaId,
    required String mediaTitle,
  }) async {
    try {
      final existing = await _isar.mediaPreferences.getByMediaTitle(
        args.mediaTitle,
      );
      final pref =
          existing ?? (MediaPreference()..mediaTitle = args.mediaTitle);

      pref.preferredSourceId = sourceInfo.id;
      pref.preferredSourceName = sourceInfo.name;
      pref.preferredSourceType = sourceInfo.type.name;
      pref.manualOverrideId = mediaId;
      pref.manualOverrideTitle = mediaTitle;

      await _isar.writeTxn(() async => await _isar.mediaPreferences.put(pref));

      if (state.hasValue && state.value != null) {
        state = AsyncData(
          state.value!.copyWith(
            sourceInfo: sourceInfo,
            manualOverrideId: mediaId,
            manualOverrideTitle: mediaTitle,
          ),
        );
      }
    } catch (e, st) {
      _log.e('Failed to save watch preference', e, st);
    }
  }

  void setPreferredAiringTracker(TrackerType tracker) {
    final log = _log.child('setPreferredAiringTracker');
    log.i('Tracker → ${tracker.displayName}');

    state = AsyncData(state.value!.copyWith(preferredAiringTracker: tracker));

    _saveToDb();
  }

  void updatePrefs(SourceInfo sourceInfo, String id, String title) {
    state = AsyncData(
      state.value!.copyWith(
        sourceInfo: sourceInfo,
        manualOverrideId: id,
        manualOverrideTitle: title,
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
        ..manualOverrideId = currentState.manualOverrideId
        ..manualOverrideTitle = currentState.manualOverrideTitle
        ..preferredAiringTracker = currentState.preferredAiringTracker?.id
        ..manualAiringTrackerId = currentState.manualAiringTrackerId;

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

  Future<void> setManualAiringTrackerId(String id) async {
    try {
      final existing = await _isar.mediaPreferences.getByMediaTitle(
        args.mediaTitle,
      );
      final newPref =
          existing ?? (MediaPreference()..mediaTitle = args.mediaTitle);

      newPref.manualAiringTrackerId = id;
      // Inherit source state
      newPref.preferredSourceId = state.value!.sourceInfo.id;
      newPref.preferredSourceName = state.value!.sourceInfo.name;
      newPref.preferredSourceType = state.value!.sourceInfo.type.name;

      await _isar.writeTxn(() async {
        await _isar.mediaPreferences.put(newPref);
      });

      state = AsyncData(state.value!.copyWith(manualAiringTrackerId: id));
    } catch (e, st) {
      _log.e('Failed to set manual airing tracker id', e, st);
    }
  }
}

final mediaPreferenceProvider =
    AsyncNotifierProvider.family<
      MediaPreferenceNotifier,
      MediaPreferenceState,
      MatchArgs
    >(MediaPreferenceNotifier.new, name: 'mediaPreferenceProvider');
