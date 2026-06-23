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
      throw Exception('No results found for $cleanTitle');
    }

    final target = cleanTitle.toLowerCase();
    final nonAlphanumeric = RegExp(r'[^a-zA-Z0-9]');
    final cleanTarget = target.replaceAll(nonAlphanumeric, '');
    final cleanRomajiTarget = romajiTitle?.toLowerCase().replaceAll(
      nonAlphanumeric,
      '',
    );

    int getScore(UnifiedMedia m) {
      int score = 0;
      final eng =
          m.title.english?.toLowerCase().replaceAll(nonAlphanumeric, '') ?? '';
      final rom =
          m.title.romaji?.toLowerCase().replaceAll(nonAlphanumeric, '') ?? '';

      if (eng.isNotEmpty && eng == cleanTarget) {
        score += 10;
      } else if (eng.isNotEmpty && cleanTarget.contains(eng)) {
        score += 5;
      } else if (eng.isNotEmpty && eng.contains(cleanTarget)) {
        score += 5;
      }

      if (cleanRomajiTarget != null) {
        if (rom.isNotEmpty && rom == cleanRomajiTarget) {
          score += 10;
        } else if (rom.isNotEmpty && cleanRomajiTarget.contains(rom)) {
          score += 5;
        } else if (rom.isNotEmpty && rom.contains(cleanRomajiTarget)) {
          score += 5;
        }
      }
      return score;
    }

    results.sort((a, b) => getScore(b).compareTo(getScore(a)));

    return results.first;
  }
}
