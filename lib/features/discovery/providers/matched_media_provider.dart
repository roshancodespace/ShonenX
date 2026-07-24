import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/extensions.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/matchmaker/match_service.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class MatchedMedia {
  final String id;
  final String title;

  const MatchedMedia({required this.id, required this.title});
}

class MatchedMediaState {
  final MatchedMedia? matchedMedia;
  final bool isLoading;
  final String? error;

  const MatchedMediaState({
    this.matchedMedia,
    this.isLoading = false,
    this.error,
  });

  MatchedMediaState copyWith({
    MatchedMedia? matchedMedia,
    bool? isLoading,
    String? error,
  }) {
    return MatchedMediaState(
      matchedMedia: matchedMedia ?? this.matchedMedia,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final matchedMediaProvider =
    AsyncNotifierProvider.family<
      MediaMatchNotifier,
      MatchedMediaState,
      MediaArgs
    >(MediaMatchNotifier.new);

class MediaMatchNotifier extends AsyncNotifier<MatchedMediaState> {
  late final MediaArgs args;

  MediaMatchNotifier(this.args);

  @override
  Future<MatchedMediaState> build() async {
    state = const AsyncLoading();
    final prefs = await ref.watch(mediaPreferenceProvider(args).future);

    if (args.sourceId != null && args.providerId != null) {
      final availableSources = args.type == MediaType.ANIME
          ? await ref.watch(availableAnimeSourcesProvider.future)
          : await ref.watch(availableMangaSourcesProvider.future);

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

      return MatchedMediaState(
        matchedMedia: MatchedMedia(
          id: args.providerId!,
          title: args.mediaTitle,
        ),
      );
    }

    if (prefs.matchedMediaId != null && prefs.matchedMediaTitle != null) {
      return MatchedMediaState(
        matchedMedia: MatchedMedia(
          id: prefs.matchedMediaId!,
          title: prefs.matchedMediaTitle!,
        ),
      );
    }

    final sourceImpl = args.type == MediaType.ANIME
        ? ref.read(animeSourceProvider(prefs.sourceInfo))
        : ref.read(mangaSourceProvider(prefs.sourceInfo));

    final result = await MediaMatchService(
      sourceImpl,
      args.type,
    ).findBestMatch(args.mediaTitle);

    if (result == null) {
      return const MatchedMediaState();
    }

    // Cache the match in Isar DB to bypass matchmaker on next launch
    Future.microtask(() {
      ref
          .read(mediaPreferenceProvider(args).notifier)
          .saveAutoMatch(result.id, result.title.availableTitle);
    });

    return MatchedMediaState(
      matchedMedia: MatchedMedia(
        id: result.id,
        title: result.title.availableTitle,
      ),
    );
  }
}
