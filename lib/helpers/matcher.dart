double calculateSimilarity(String? str1, String? str2) {
  // Handle null or empty inputs
  if (str1 == null || str2 == null) return 0.0;
  if (str1.isEmpty || str2.isEmpty) return 0.0;

  // Normalize to lowercase for case-insensitive comparison
  final s1 = str1.toLowerCase();
  final s2 = str2.toLowerCase();

  // Early exit for identical strings
  if (s1 == s2) return 1.0;

  final len1 = s1.length;
  final len2 = s2.length;

  // Create a two-row matrix to save space (O(min(m,n)) instead of O(m*n))
  final minLen = len1 < len2 ? len1 : len2;
  final maxLen = len1 > len2 ? len1 : len2;
  List<int> prevRow = List.generate(minLen + 1, (i) => i);
  List<int> currRow = List.generate(minLen + 1, (_) => 0);

  // Fill the matrix
  for (int i = 1; i <= maxLen; i++) {
    currRow[0] = i;
    for (int j = 1; j <= minLen; j++) {
      final cost = (len1 < len2 ? s2[i - 1] : s1[i - 1]) == (len1 < len2 ? s1[j - 1] : s2[j - 1]) ? 0 : 1;
      currRow[j] = [
        currRow[j - 1] + 1, // Insertion
        prevRow[j] + 1,     // Deletion
        prevRow[j - 1] + cost // Substitution
      ].reduce((a, b) => a < b ? a : b);
    }
    // Swap rows
    final temp = prevRow;
    prevRow = currRow;
    currRow = temp;
  }

  final levenshteinDistance = prevRow[minLen];

  // Alternative normalization: Use average length for better balance
  final avgLength = (len1 + len2) / 2;
  double levenshteinSimilarity = 1.0 - (levenshteinDistance / avgLength);

  // Bonus: Word overlap heuristic for anime titles
  final words1 = s1.split(RegExp(r'\s+'));
  final words2 = s2.split(RegExp(r'\s+'));
  final commonWords = words1.where((w) => words2.contains(w)).length;
  final maxWords = words1.length > words2.length ? words1.length : words2.length;
  final wordSimilarity = commonWords / maxWords;

  // Combine scores (weighted: 70% Levenshtein, 30% word overlap)
  return 0.7 * levenshteinSimilarity + 0.3 * wordSimilarity;
}