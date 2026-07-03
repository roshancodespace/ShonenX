import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/matchmaker/match_service.dart';

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

class MatchArgs {
  final String mediaTitle;
  final MediaType type;
  final String? sourceId;
  final String? providerId;

  const MatchArgs({
    required this.mediaTitle,
    required this.type,
    this.sourceId,
    this.providerId,
  });

  factory MatchArgs.fromMedia(UnifiedMedia media) {
    return MatchArgs(
      mediaTitle: media.title.availableTitle,
      type: media.type,
      sourceId: media.sourceId,
      providerId: media.id,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchArgs &&
          mediaTitle == other.mediaTitle &&
          type == other.type &&
          sourceId == other.sourceId &&
          providerId == other.providerId;

  @override
  int get hashCode => Object.hash(mediaTitle, type, sourceId, providerId);
}

final matchedMediaProvider =
    AsyncNotifierProvider.family<
      MediaMatchNotifier,
      MatchedMediaState,
      MatchArgs
    >(MediaMatchNotifier.new);

class MediaMatchNotifier extends AsyncNotifier<MatchedMediaState> {
  late final MatchArgs args;

  MediaMatchNotifier(this.args);

  @override
  Future<MatchedMediaState> build() async {
    state = const AsyncLoading();
    final prefs = await ref.watch(mediaPreferenceProvider(args).future);

    if (prefs.manualOverrideId != null && prefs.manualOverrideTitle != null) {
      return MatchedMediaState(
        matchedMedia: MatchedMedia(
          id: prefs.manualOverrideId!,
          title: prefs.manualOverrideTitle!,
        ),
      );
    }

    if (args.sourceId != null &&
        args.providerId != null &&
        prefs.sourceInfo.id == args.sourceId) {
      return MatchedMediaState(
        matchedMedia: MatchedMedia(
          id: args.providerId!,
          title: args.mediaTitle,
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
