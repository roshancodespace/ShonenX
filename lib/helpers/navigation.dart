import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/browse/model/search_filter.dart';

void navigateToDetail(
  BuildContext context,
  UniversalMedia media,
  String tag, {
  bool forceFetch = false,
}) {
  context.push('/details?tag=$tag&forceFetch=$forceFetch', extra: media);
}

void navigateToBrowse(
  BuildContext context, {
  String? keyword,
  SearchFilter? filter,
}) {
  final uri = Uri(
    path: '/browse',
    queryParameters: keyword != null ? {'keyword': keyword} : null,
  );
  context.go(uri.toString(), extra: filter);
}
void navigateToWatch({
  required BuildContext context,
  required String mediaId,
  required String animeName,
  required String animeFormat,
  required String animeCover,
  required List<EpisodeDataModel> episodes,
  required int currentEpisode,
  String? animeId,
  int? startAt,
}) {
  final queryParams = <String, String>{
    'animeName': animeName,
    'animeFormat': animeFormat,
    'animeCover': animeCover,
    'episode': currentEpisode.toString(),
  };

  if (animeId != null) {
    queryParams['animeId'] = animeId;
  }

  if (startAt != null) {
    queryParams['startAt'] = startAt.toString();
  }

  final uri = Uri(
    path: '/watch/$mediaId',
    queryParameters: queryParams,
  );

  AppLogger.d('Navigating to watch screen: $uri');

  context.push(uri.toString(), extra: episodes);
}
