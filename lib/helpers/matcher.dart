import 'dart:math';

/// Filters and sorts provider search results by similarity score
List<({T result, double similarity})> getBestMatches<T>({
  required List<T> results,
  required String title,
  required String? Function(T r) nameSelector,
  required String? Function(T r) idSelector,
  double minThreshold = 0.1,
}) {
  return results
      .where((r) => nameSelector(r) != null && idSelector(r) != null)
      .map((r) => (
            result: r,
            similarity: getSimilarityScore(
              nameSelector(r)!.toLowerCase(),
              title.toLowerCase(),
            ),
          ))
      .where((p) => p.similarity > minThreshold)
      .toList()
    ..sort((a, b) => b.similarity.compareTo(a.similarity));
}

/// Calculates the similarity score between two strings (0.0 - 1.0).
/// Uses normalized Levenshtein distance.
double getSimilarityScore(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0.0;

  final lenA = a.length;
  final lenB = b.length;
  final distance = _levenshtein(a, b);

  // Similarity = 1 - (editDistance / maxLength)
  return 1.0 - (distance / max(lenA, lenB));
}

/// Internal Levenshtein distance implementation
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
      v1[j + 1] = [
        v1[j] + 1,      // Deletion
        v0[j + 1] + 1,  // Insertion
        v0[j] + cost,   // Substitution
      ].reduce(min);
    }

    for (var j = 0; j < v0.length; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[t.length];
}
