import 'package:shonenx/shared/models/unified_media.dart';

class TitleMatcher {
  static const double minimumSimilarityThreshold = 0.85;

  static List<String> extractTargetTitles(UnifiedMedia media) {
    final titles = <String>[];
    void add(String? t) {
      if (t != null && t.trim().isNotEmpty && !titles.contains(t.trim())) {
        titles.add(t.trim());
      }
    }

    add(media.title.english);
    add(media.title.romaji);
    add(media.title.native);
    add(media.title.availableTitle);
    return titles;
  }

  static double calculateSimilarity(String a, String b) {
    final cleanA = _normalize(a);
    final cleanB = _normalize(b);

    if (cleanA.isEmpty || cleanB.isEmpty) return 0.0;
    if (cleanA == cleanB) return 1.0;

    if (cleanA.length < 2 || cleanB.length < 2) {
      return cleanA == cleanB ? 1.0 : 0.0;
    }

    final bigramsA = <String, int>{};
    for (int i = 0; i < cleanA.length - 1; i++) {
      final bg = cleanA.substring(i, i + 2);
      bigramsA[bg] = (bigramsA[bg] ?? 0) + 1;
    }

    int intersection = 0;
    for (int i = 0; i < cleanB.length - 1; i++) {
      final bg = cleanB.substring(i, i + 2);
      final count = bigramsA[bg] ?? 0;
      if (count > 0) {
        bigramsA[bg] = count - 1;
        intersection++;
      }
    }

    return (2.0 * intersection) / ((cleanA.length - 1) + (cleanB.length - 1));
  }

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').trim();
  }

  static ({T item, double score})? findBestMatch<T>({
    required List<String> targetTitles,
    required List<T> candidates,
    required List<String> Function(T item) extractCandidateTitles,
    double threshold = minimumSimilarityThreshold,
  }) {
    if (targetTitles.isEmpty || candidates.isEmpty) return null;

    final validTargets = targetTitles
        .where((t) => t.trim().isNotEmpty)
        .toList();
    if (validTargets.isEmpty) return null;

    T? bestItem;
    double bestScore = 0.0;

    for (final candidate in candidates) {
      final candidateTitles = extractCandidateTitles(
        candidate,
      ).where((t) => t.trim().isNotEmpty).toList();

      for (final target in validTargets) {
        for (final candTitle in candidateTitles) {
          final score = calculateSimilarity(target, candTitle);
          if (score > bestScore) {
            bestScore = score;
            bestItem = candidate;
          }
        }
      }
    }

    if (bestItem != null && bestScore >= threshold) {
      return (item: bestItem, score: bestScore);
    }

    return null;
  }
}
