import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/providers/source_preference_provider.dart';
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
  final String? sourceId;
  final String? providerId;

  const MatchArgs({
    required this.mediaTitle,
    this.sourceId,
    this.providerId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchArgs &&
          mediaTitle == other.mediaTitle &&
          sourceId == other.sourceId &&
          providerId == other.providerId;

  @override
  int get hashCode => Object.hash(mediaTitle, sourceId, providerId);
}

final matchedMediaProvider =
    AsyncNotifierProvider.family<MediaMatchNotifier, MatchedMediaState, String>(
      MediaMatchNotifier.new,
    );

class MediaMatchNotifier extends AsyncNotifier<MatchedMediaState> {
  late final String mediaTitle;

  MediaMatchNotifier(this.mediaTitle);

  @override
  Future<MatchedMediaState> build() async {
    state = const AsyncLoading();
    final prefs = await ref.watch(sourcePreferenceProvider(mediaTitle).future);

    if (prefs.manualOverrideId != null && prefs.manualOverrideTitle != null) {
      return MatchedMediaState(
        matchedMedia: MatchedMedia(
          id: prefs.manualOverrideId!,
          title: prefs.manualOverrideTitle!,
        ),
      );
    }

    final animeSource = ref.read(animeSourceProvider(prefs.sourceInfo));

    final result = await MediaMatchService(
      animeSource,
      MediaType.ANIME,
    ).findBestMatch(mediaTitle);

    if (result == null) {
      return const MatchedMediaState();
    }

    // Cache the match in SourcePreference to bypass matchmaker on next launch
    Future.microtask(() {
      ref.read(sourcePreferenceProvider(mediaTitle).notifier).setManualOverrides(
            result.id,
            result.title.availableTitle,
          );
    });

    return MatchedMediaState(
      matchedMedia: MatchedMedia(
        id: result.id,
        title: result.title.availableTitle,
      ),
    );
  }
}
