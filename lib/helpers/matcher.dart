import 'dart:math';

/// Filters and sorts provider search results by similarity score.
List<({T result, double similarity})> getBestMatches<T>({
  required List<T> results,
  required String title,
  required String? Function(T r) nameSelector,
  required String? Function(T r) idSelector,
  double minThreshold = 0.1,
}) {
  final normalizedQuery = _normalize(title);
  final queryTokens = _tokenize(normalizedQuery);
  final querySeason = _extractSeason(normalizedQuery);

  return results
      .where((r) => nameSelector(r) != null && idSelector(r) != null)
      .map((r) {
        final targetName = nameSelector(r)!;
        final normalizedTarget = _normalize(targetName);
        final targetTokens = _tokenize(normalizedTarget);
        final targetSeason = _extractSeason(normalizedTarget);

        final score = _calculateHybridScore(
          normalizedQuery,
          normalizedTarget,
          queryTokens,
          targetTokens,
          querySeason,
          targetSeason,
        );

        return (result: r, similarity: score);
      })
      .where((p) => p.similarity > minThreshold)
      .toList()
    ..sort((a, b) => b.similarity.compareTo(a.similarity));
}

/// Calculates a hybrid similarity score based on multiple factors.
double _calculateHybridScore(
  String nQuery,
  String nTarget,
  Set<String> qTokens,
  Set<String> tTokens,
  int? qSeason,
  int? tSeason,
) {
  // Season Mismatch Penalty: heavily penalize if seasons are present and don't match.
  if (qSeason != null && tSeason != null && qSeason != tSeason) {
    return 0.0;
  }

  // Jaccard Similarity (token overlap)
  final intersection = qTokens.intersection(tTokens).length;
  final union = qTokens.union(tTokens).length;
  final jaccardScore = union == 0 ? 0.0 : intersection / union;

  // Levenshtein Similarity (edit distance)
  final levenshteinScore = _getLevenshteinSimilarity(nQuery, nTarget);

  // Substring Bonus: if one string is a substring of the other.
  double substringBonus = 0.0;
  if (nQuery.contains(nTarget) || nTarget.contains(nQuery)) {
    substringBonus = 0.1;
  }

  // Season Match Bonus: boost if seasons are present and match.
  double seasonBonus = 0.0;
  if (qSeason != null && tSeason != null && qSeason == tSeason) {
    seasonBonus = 0.15;
  }

  // Weighted combination of scores.
  return (jaccardScore * 0.7) +
      (levenshteinScore * 0.3) +
      substringBonus +
      seasonBonus;
}

/// Normalizes the string: lowercase, roman numerals to arabic, standardizes seasons, removes special characters.
String _normalize(String input) {
  String s = input.toLowerCase();

  // Replace Roman Numerals (up to 10) using word boundaries to avoid false positives.
  final romanMap = {
    r'\bix\b': '9',
    r'\bviii\b': '8',
    r'\bvii\b': '7',
    r'\bvi\b': '6',
    r'\bv\b': '5',
    r'\biv\b': '4',
    r'\biii\b': '3',
    r'\bii\b': '2',
  };

  romanMap.forEach((regex, replacement) {
    s = s.replaceAll(RegExp(regex), replacement);
  });

  // Normalize season formats (e.g., "s4" -> "season 4", "4th season" -> "season 4").
  s = s.replaceAllMapped(RegExp(r'\bs(\d+)\b'), (m) => 'season ${m.group(1)}');
  s = s.replaceAllMapped(RegExp(r'\b(\d+)(?:st|nd|rd|th)?\s+season\b'),
      (m) => 'season ${m.group(1)}');

  // Remove non-alphanumeric characters and collapse multiple spaces.
  s = s.replaceAllMapped(
      RegExp(r'×|[^a-z0-9\s]'), (m) => m[0] == '×' ? ' x ' : ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Extracts unique tokens from the normalized string.
Set<String> _tokenize(String normalizedInput) {
  return normalizedInput.split(' ').where((s) => s.isNotEmpty).toSet();
}

/// Extracts a season number if explicitly present or implied at the end of the string.
int? _extractSeason(String normalizedInput) {
  // Explicit "season X" pattern.
  final match = RegExp(r'season\s+(\d+)').firstMatch(normalizedInput);
  if (match != null) {
    return int.tryParse(match.group(1)!);
  }

  // Implicit number at the end (e.g., "My Hero Academia 4").
  // Filters out years or very large numbers to reduce false positives.
  final endNumberMatch = RegExp(r'\s+(\d+)$').firstMatch(normalizedInput);
  if (endNumberMatch != null) {
    final num = int.tryParse(endNumberMatch.group(1)!);
    if (num != null && num < 100) {
      return num;
    }
  }

  return null;
}

/// Calculates Levenshtein similarity (0.0 - 1.0).
double _getLevenshteinSimilarity(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final distance = _levenshtein(a, b);
  return 1.0 - (distance / max(a.length, b.length));
}

/// Calculates the Levenshtein edit distance between two strings.
int _levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  final v0 = List<int>.filled(t.length + 1, 0);
  final v1 = List<int>.filled(t.length + 1, 0);

  for (var i = 0; i <= t.length; i++) {
    v0[i] = i;
  }

  for (var i = 0; i < s.length; i++) {
    v1[0] = i + 1;
    for (var j = 0; j < t.length; j++) {
      final cost = s[i] == t[j] ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }
    for (var j = 0; j < v0.length; j++) {
      v0[j] = v1[j];
    }
  }
  return v1[t.length];
}
