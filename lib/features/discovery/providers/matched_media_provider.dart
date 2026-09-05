import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/matchmaker/match_service.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class MatchedMedia {
  final String id;
  final String title;

  const MatchedMedia({required this.id, required this.title});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchedMedia &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, title);
}

class MatchedMediaState {
  final SourceInfo sourceInfo;
  final MatchedMedia? matchedMedia;
  final bool isLoading;
  final String? error;

  const MatchedMediaState({
    required this.sourceInfo,
    this.matchedMedia,
    this.isLoading = false,
    this.error,
  });

  MatchedMediaState copyWith({
    SourceInfo? sourceInfo,
    MatchedMedia? matchedMedia,
    bool? isLoading,
    String? error,
  }) {
    return MatchedMediaState(
      sourceInfo: sourceInfo ?? this.sourceInfo,
      matchedMedia: matchedMedia ?? this.matchedMedia,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchedMediaState &&
          runtimeType == other.runtimeType &&
          sourceInfo == other.sourceInfo &&
          matchedMedia == other.matchedMedia &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => Object.hash(sourceInfo, matchedMedia, isLoading, error);
}

final matchedMediaProvider =
    AsyncNotifierProvider.family<
      MediaMatchNotifier,
      MatchedMediaState,
      MediaArgs
    >(MediaMatchNotifier.new);

class MediaMatchNotifier extends AsyncNotifier<MatchedMediaState> {
  late final MediaArgs args;
  late final _log = AppLogger.scope(MediaMatchNotifier).child(args.mediaTitle);

  MediaMatchNotifier(this.args);

  @override
  Future<MatchedMediaState> build() async {
    state = const AsyncLoading();
    final prefs = await ref.watch(mediaPreferenceProvider(args).future);

    if (args.sourceId != null && args.providerId != null) {
      final availableSources = await ref.watch(
        args.type.availableSourcesProvider.future,
      );

      final sourceInfo =
          availableSources.firstWhereOrNull((s) => s.id == args.sourceId) ??
          prefs.sourceInfo;

      if (prefs.sourceInfo.id != sourceInfo.id ||
          prefs.matchedMediaId != args.providerId ||
          prefs.matchedMediaTitle != args.mediaTitle) {
        Future.microtask(() {
          ref
              .read(mediaPreferenceProvider(args).notifier)
              .updatePrefs(sourceInfo, args.providerId!, args.mediaTitle);
        });
      }

      _log.i(
        'Direct source match: "${args.mediaTitle}" (${args.providerId}) on ${args.sourceId}',
      );

      return MatchedMediaState(
        sourceInfo: sourceInfo,
        matchedMedia: MatchedMedia(
          id: args.providerId!,
          title: args.mediaTitle,
        ),
      );
    }

    if (prefs.matchedMediaId != null && prefs.matchedMediaTitle != null) {
      _log.i(
        'Using saved match: "${prefs.matchedMediaTitle}" (${prefs.matchedMediaId}) on ${prefs.sourceInfo.name}',
      );
      return MatchedMediaState(
        sourceInfo: prefs.sourceInfo,
        matchedMedia: MatchedMedia(
          id: prefs.matchedMediaId!,
          title: prefs.matchedMediaTitle!,
        ),
      );
    }

    _log.i('Searching match on ${prefs.sourceInfo.name}...');
    final sourceImpl = args.type.usesAnimeSources
        ? ref.read(animeSourceProvider(prefs.sourceInfo))
        : ref.read(mangaSourceProvider(prefs.sourceInfo));

    final result = await MediaMatchService(
      sourceImpl,
      args.type,
    ).findBestMatch(args.mediaTitle);

    if (result == null) {
      _log.w('No match found on ${prefs.sourceInfo.name}');
      return MatchedMediaState(sourceInfo: prefs.sourceInfo);
    }

    _log.s(
      'Matched → "${result.title.availableTitle}" (${result.id}) on ${prefs.sourceInfo.name}',
    );

    // Cache the match in Isar DB to bypass matchmaker on next launch
    Future.microtask(() {
      ref
          .read(mediaPreferenceProvider(args).notifier)
          .saveAutoMatch(result.id, result.title.availableTitle);
    });

    return MatchedMediaState(
      sourceInfo: prefs.sourceInfo,
      matchedMedia: MatchedMedia(
        id: result.id,
        title: result.title.availableTitle,
      ),
    );
  }
}
