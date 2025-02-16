double calculateSimilarity(String? str1, String? str2) {
  if (str1 == null || str2 == null) return 0.0;

  final len1 = str1.length;
  final len2 = str2.length;

  if (len1 == 0 || len2 == 0) return 0.0;
  if (str1 == str2) return 1.0;

  // Create a matrix to store distances
  List<List<int>> dp = List.generate(
    len1 + 1,
    (i) => List<int>.filled(len2 + 1, 0),
  );

  for (int i = 0; i <= len1; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= len2; j++) {
    dp[0][j] = j;
  }

  for (int i = 1; i <= len1; i++) {
    for (int j = 1; j <= len2; j++) {
      int cost = str1[i - 1] == str2[j - 1] ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1, // Deletion
        dp[i][j - 1] + 1, // Insertion
        dp[i - 1][j - 1] + cost // Substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  int levenshteinDistance = dp[len1][len2];

  // FIX: Ensure denominator is never zero
  int maxLength = len1 > len2 ? len1 : len2;
  return 1.0 - (levenshteinDistance / maxLength);
}
