import 'package:shonenx/shared/models/unified_media.dart';

class RecommendedAnime {
  final UnifiedMedia media;
  final double matchScore;
  final String reason;
  final List<String> matchingGenres;
  final bool isDirectSeed;

  const RecommendedAnime({
    required this.media,
    required this.matchScore,
    required this.reason,
    this.matchingGenres = const [],
    this.isDirectSeed = false,
  });
}
