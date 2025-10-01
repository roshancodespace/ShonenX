import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/utils/app_logger.dart';

void navigateToDetail(BuildContext context, Media media, String tag) {
  context.push('/details?tag=$tag', extra: media);
}

/// Helper to construct the route and navigate to the watch screen.
void navigateToWatch(
    {required BuildContext context,
    required WidgetRef ref,
    required String? animeId,
    required String mediaId,
    required String animeName,
    required List<EpisodeDataModel> episodes,
    int? startAt,
    String? mMangaUrl}) {
  // final progress = ref
  //     .read(animeWatchProgressProvider.notifier)
  //     .getMostRecentEpisodeProgressByAnimeId(animeMedia.id!);

  // final episode = (progress?.episodeNumber ?? 0) + plusEpisode;
  // final startAt = progress?.progressInSeconds ?? 0;
  // final encodedName = Uri.encodeComponent(animeName);
  final route = '/watch/$mediaId?animeId=$animeId'
      '&animeName=$animeName'
      '&episode=1&mMangaUrl=$mMangaUrl&startAt=$startAt';
  AppLogger.d('Navigating to watch screen: $route');
  context.push(route, extra: episodes);
}
