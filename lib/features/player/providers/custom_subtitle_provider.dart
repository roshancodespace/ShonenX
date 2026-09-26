import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';

final customSubtitleProvider = FutureProvider.autoDispose<List<SubtitleCue>>((
  ref,
) async {
  final playerState = ref.watch(playerControllerProvider);
  final subtitleUrl = playerState.activeSubtitle?.url;
  final headers = playerState.activeStream?.headers;

  if (subtitleUrl == null || subtitleUrl.isEmpty) return [];

  final http = ref.read(httpClientProvider);
  return SubtitleParser.parseFromUrl(
    subtitleUrl,
    httpClient: http,
    headers: headers,
  );
});
