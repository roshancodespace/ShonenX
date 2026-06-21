import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/domain/media_source_preference.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class SourcePreferenceState {
  final SourceInfo sourceInfo;
  final String? manualOverrideId;
  final String? manualOverrideTitle;

  SourcePreferenceState({
    required this.sourceInfo,
    this.manualOverrideId,
    this.manualOverrideTitle,
  });

  SourcePreferenceState copyWith({
    SourceInfo? sourceInfo,
    String? manualOverrideId,
    String? manualOverrideTitle,
  }) {
    return SourcePreferenceState(
      sourceInfo: sourceInfo ?? this.sourceInfo,
      manualOverrideId: manualOverrideId ?? this.manualOverrideId,
      manualOverrideTitle: manualOverrideTitle ?? this.manualOverrideTitle,
    );
  }
}

class SourcePreferencNotifier extends AsyncNotifier<SourcePreferenceState> {
  late final MatchArgs args;
  late final _isar = ref.read(databaseProvider);
  late final _log = AppLogger.scope(
    SourcePreferencNotifier,
  ).child(args.mediaTitle);

  SourcePreferencNotifier(this.args);

  @override
  Future<SourcePreferenceState> build() async {
    final log = _log.child('build');

    try {
      final savedPref = await _isar.mediaSourcePreferences.getByMediaTitle(
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

      final resolvedSource = (type != null && preferredId != null)
          ? availableSourcesInfo.firstWhereOrNull(
                  (s) => s.id == preferredId && s.name == preferredName,
                ) ??
                globalDefaultSourceInfo
          : globalDefaultSourceInfo;

      log.i('Resolved → ${resolvedSource.name} (${resolvedSource.id})');

      return SourcePreferenceState(
        sourceInfo: resolvedSource,
        manualOverrideId: savedPref?.manualOverrideId,
        manualOverrideTitle: savedPref?.manualOverrideTitle,
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
      SourcePreferenceState(
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

  void updatePrefs(SourceInfo sourceInfo, String id, String title) {
    state = AsyncData(
      SourcePreferenceState(
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
      final pref = MediaSourcePreference()
        ..mediaTitle = args.mediaTitle
        ..preferredSourceId = currentState.sourceInfo.id
        ..preferredSourceName = currentState.sourceInfo.name
        ..preferredSourceType = currentState.sourceInfo.type.name
        ..manualOverrideId = currentState.manualOverrideId
        ..manualOverrideTitle = currentState.manualOverrideTitle;

      await _isar.writeTxn(
        () async => await _isar.mediaSourcePreferences.put(pref),
      );

      log.s('Saved');
    } catch (e, st) {
      log.e('Save failed', e, st);
    }
  }

  Future<void> clearPreference() async {
    final log = _log.child('clearPreference');

    try {
      await _isar.writeTxn(
        () async => await _isar.mediaSourcePreferences.deleteByMediaTitle(
          args.mediaTitle,
        ),
      );

      ref.invalidateSelf();
      log.s('Cleared');
    } catch (e, st) {
      log.e('Clear failed', e, st);
    }
  }
}

final sourcePreferenceProvider =
    AsyncNotifierProvider.family<
      SourcePreferencNotifier,
      SourcePreferenceState,
      MatchArgs
    >(SourcePreferencNotifier.new, name: 'sourcePreferenceProvider');
