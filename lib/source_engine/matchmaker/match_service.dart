import 'dart:async';

import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';

class MediaMatchService {
  final MediaSource _mediaSource;
  final MediaType _type;

  MediaMatchService(this._mediaSource, this._type);

  Future<UnifiedMedia?> findBestMatch(
    String cleanTitle, {
    String? romajiTitle,
  }) async {
    var results = await _mediaSource.search(cleanTitle, _type);

    if (results.isEmpty && romajiTitle != null) {
      results = await _mediaSource.search(romajiTitle, _type);
    }

    if (results.isEmpty) {
      return null;
    }

    final target = cleanTitle.toLowerCase();
    final nonAlphanumeric = RegExp(r'[^a-zA-Z0-9]');
    final cleanTarget = target.replaceAll(nonAlphanumeric, '');
    final cleanRomajiTarget = romajiTitle?.toLowerCase().replaceAll(
      nonAlphanumeric,
      '',
    );

    int getScore(UnifiedMedia m) {
      int maxScore = 0;
      final candidates = [
        m.title.english,
        m.title.romaji,
        m.title.native,
        m.title.availableTitle,
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
