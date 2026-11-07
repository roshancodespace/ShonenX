import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/subtitle_translation_provider.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';

/// Fetches and parses the original untranslated cues from the active subtitle URL.
final rawCustomSubtitleProvider =
    FutureProvider.autoDispose<List<SubtitleCue>>((ref) async {
  final playerState = ref.watch(playerControllerProvider);
  final subtitleUrl = playerState.activeSubtitle?.url;
  final headers = playerState.activeStream?.headers;

  if (subtitleUrl == null ||
      subtitleUrl.isEmpty ||
      subtitleUrl.startsWith('internal:')) {
    return [];
  }

  final http = ref.read(httpClientProvider);
  return SubtitleParser.parseFromUrl(
    subtitleUrl,
    httpClient: http,
    headers: headers,
  );
});

/// Supplies subtitle cues to the player overlay. If runtime subtitle translation
/// is enabled and translated cues are ready for the active URL, it serves them;
/// otherwise, it falls back to the original parsed raw cues.
final customSubtitleProvider =
    FutureProvider.autoDispose<List<SubtitleCue>>((ref) async {
  final rawCues = await ref.watch(rawCustomSubtitleProvider.future);
  if (rawCues.isEmpty) return [];

  final translationState = ref.watch(runtimeSubtitleTranslationProvider);
  final playerState = ref.watch(playerControllerProvider);
  final subtitleUrl = playerState.activeSubtitle?.url;

  if (translationState.isEnabled &&
      translationState.currentSourceUrl == subtitleUrl &&
      translationState.translatedCues != null &&
      translationState.translatedCues!.isNotEmpty) {
    return translationState.translatedCues!;
  }

  return rawCues;
});
