import 'package:shonenx/features/recommendations/domain/models/recommended_anime.dart';
import 'package:shonenx/features/recommendations/domain/models/user_taste_profile.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class RecommendationEngine {
  const RecommendationEngine();

  /// Scores, deduplicates, and ranks candidate anime based on the user's taste profile.
  List<RecommendedAnime> rankCandidates({
    required UserTasteProfile profile,
    required List<UnifiedMedia> candidates,
    Map<String, String>? seedReasons,
  }) {
    if (candidates.isEmpty) return const [];

    final excluded = profile.excludedIds;
    final scoredList = <RecommendedAnime>[];
    final seenIds = <String>{};

    for (final candidate in candidates) {
      if (candidate.id.isEmpty) continue;
      // Filter out anime the user already liked, completed, is watching, or dropped
      if (excluded.contains(candidate.id)) continue;
      if (seenIds.contains(candidate.id)) continue;
      seenIds.add(candidate.id);

      double score = 0.0;
      final matchingPositiveGenres = <String>[];
      final candidateGenres = candidate.genres ?? const [];

      // 1. Check direct seed recommendation link
      final seedReason = seedReasons?[candidate.id];
      final isDirectSeed = seedReason != null;
      if (isDirectSeed) {
        score += 25.0;
      }

      // 2. Score based on genre affinities (positive and negative)
      for (final genre in candidateGenres) {
        final affinity = profile.genreAffinities[genre] ?? 0.0;
        if (affinity > 0) {
          score += affinity.clamp(0.0, 10.0);
          matchingPositiveGenres.add(genre);
        } else if (affinity < 0) {
          // Negative penalty for genres associated with dropped anime
          score += affinity.clamp(-15.0, 0.0);
        }
      }

      // 3. Quality boost based on community score
      final rawScore = candidate.score ?? 7.0;
      score += (rawScore * 0.4);

      // If the penalty pushed score below 0 and it's not a direct seed, skip
      if (score <= 0 && !isDirectSeed) continue;

      // 4. Determine recommendation reason
      String reason;
      if (seedReason != null) {
        reason = seedReason;
      } else if (matchingPositiveGenres.isNotEmpty) {
        final topGenres = matchingPositiveGenres.take(2).join(' & ');
        reason = 'Top match for your taste in $topGenres';
      } else {
        reason = 'Recommended based on your library activity';
      }

      scoredList.add(
        RecommendedAnime(
          media: candidate,
          matchScore: score,
          reason: reason,
          matchingGenres: matchingPositiveGenres,
          isDirectSeed: isDirectSeed,
        ),
      );
    }

    // Sort descending by calculated match score
    scoredList.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return scoredList;
  }
}
