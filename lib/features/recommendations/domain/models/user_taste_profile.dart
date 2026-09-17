import 'package:shonenx/shared/models/unified_media.dart';

class UserTasteProfile {
  final Map<String, double> genreAffinities;
  final Map<String, double> tagAffinities;
  final List<UnifiedMedia> seedAnime;
  final Set<String> excludedIds;
  final int likedCount;
  final int completedCount;
  final int watchingCount;
  final int planningCount;
  final int droppedCount;

  const UserTasteProfile({
    this.genreAffinities = const {},
    this.tagAffinities = const {},
    this.seedAnime = const [],
    this.excludedIds = const {},
    this.likedCount = 0,
    this.completedCount = 0,
    this.watchingCount = 0,
    this.planningCount = 0,
    this.droppedCount = 0,
  });

  bool get hasAnySignals =>
      likedCount > 0 ||
      completedCount > 0 ||
      watchingCount > 0 ||
      planningCount > 0 ||
      droppedCount > 0;

  List<String> get topPositiveGenres {
    final entries = genreAffinities.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  List<String> get topNegativeGenres {
    final entries = genreAffinities.entries
        .where((e) => e.value < 0)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }
}
