import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';

class EpisodePlaybackProgress {
  final double progress; // 0.0 to 1.0
  final int positionMs;
  final int durationMs;
  final String? remainingText;
  final bool isCompleted;

  const EpisodePlaybackProgress({
    required this.progress,
    this.positionMs = 0,
    this.durationMs = 0,
    this.remainingText,
    this.isCompleted = false,
  });

  bool get hasProgress => progress > 0.0;
  bool get isInProgress => progress > 0.02 && !isCompleted;

  factory EpisodePlaybackProgress.fromWatchEntry(
    WatchHistoryEntry entry, {
    bool isMarkedWatched = false,
  }) {
    final pos = entry.positionInMilliseconds;
    final dur = entry.durationInMilliseconds;
    if (dur <= 0) {
      return EpisodePlaybackProgress(
        progress: isMarkedWatched ? 1.0 : 0.0,
        positionMs: pos,
        durationMs: dur,
        isCompleted: isMarkedWatched,
      );
    }
    final rawProgress = (pos / dur).clamp(0.0, 1.0);
    final completed = isMarkedWatched || rawProgress >= 0.92;
    final remainingText =
        formatTimeRemaining(remainingMs > 0 ? remainingMs : 0);

    return EpisodePlaybackProgress(
      progress: rawProgress,
      positionMs: pos,
      durationMs: dur,
      remainingText: remainingText,
      isCompleted: completed,
    );
  }

  factory EpisodePlaybackProgress.fromReadEntry(
    ReadHistoryEntry entry, {
    bool isMarkedRead = false,
  }) {
    final page = entry.positionPage;
    final total = entry.totalPages;
    if (total <= 0) {
      return EpisodePlaybackProgress(
        progress: isMarkedRead ? 1.0 : 0.0,
        positionMs: page,
        durationMs: total,
        isCompleted: isMarkedRead,
      );
    }
    final rawProgress = (page / total).clamp(0.0, 1.0);
    final completed = isMarkedRead || page >= total;
    final remainingPages = total - page;
    final remainingText =
        remainingPages > 0 ? '$remainingPages p. left' : 'Completed';

    return EpisodePlaybackProgress(
      progress: rawProgress,
      positionMs: page,
      durationMs: total,
      remainingText: remainingText,
      isCompleted: completed,
    );
  }
}
