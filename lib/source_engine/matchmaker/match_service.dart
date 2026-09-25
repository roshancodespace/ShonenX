import 'dart:async';

import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';

class MediaMatchService {
  final MediaSource _mediaSource;
  final MediaType _type;

  MediaMatchService(this._mediaSource, this._type);

  Future<UnifiedMedia?> findBestMatch(MediaTitle mediaTitle) async {
    var results = await _mediaSource.search(mediaTitle.getPreferedTitle, _type);

    if (results.isEmpty && mediaTitle.romaji != null) {
      results = await _mediaSource.search(mediaTitle.romaji!, _type);
    }

    if (results.isEmpty) {
      return null;
    }

    final target = mediaTitle.getPreferedTitle.toLowerCase();
    final nonAlphanumeric = RegExp(r'[^a-zA-Z0-9]');
    final cleanTarget = target.replaceAll(nonAlphanumeric, '');
    final cleanRomajiTarget = mediaTitle.romaji?.toLowerCase().replaceAll(
      nonAlphanumeric,
      '',
    );

    int getScore(UnifiedMedia m) {
      int maxScore = 0;
      final candidates =
          [
                m.title.english,
                m.title.romaji,
                m.title.native,
                m.title.getPreferedTitle,
              ]
              .where((t) => t != null && t.trim().isNotEmpty)
              .map((t) => t!.toLowerCase().replaceAll(nonAlphanumeric, ''))
              .toSet();

      final targets = [
        cleanTarget,
        if (cleanRomajiTarget != null) cleanRomajiTarget,
      ];

      for (final cand in candidates) {
        if (cand.isEmpty) continue;
        for (final tgt in targets) {
          if (tgt.isEmpty) continue;
          int currentScore = 0;
          if (cand == tgt) {
            currentScore = 10;
          } else if (tgt.contains(cand) || cand.contains(tgt)) {
            currentScore = 5;
          }
          if (currentScore > maxScore) {
            maxScore = currentScore;
          }
        }
      }
      return maxScore;
    }

    results.sort((a, b) => getScore(b).compareTo(getScore(a)));

    return results.first;
  }
}
