import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';

class MediaListEntry {
  final int id;
  final Media media;
  final String status;
  final double score;
  final int progress;
  final int repeat;
  final bool isPrivate;
  final String notes;
  final FuzzyDate? startedAt;
  final FuzzyDate? completedAt;

  const MediaListEntry({
    required this.id,
    required this.media,
    required this.status,
    required this.score,
    required this.progress,
    required this.repeat,
    required this.isPrivate,
    required this.notes,
    this.startedAt,
    this.completedAt,
  });

  factory MediaListEntry.fromMedia(Media media) {
    return MediaListEntry(
      id: media.id,
      media: media,
      status: 'CURRENT',
      score: 0,
      progress: 0,
      repeat: 0,
      isPrivate: false,
      notes: '',
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media': media.toJson(),
      'status': status,
      'score': score,
      'progress': progress,
      'repeat': repeat,
      'private': isPrivate,
      'notes': notes,
      'startedAt': startedAt?.toJson(),
      'completedAt': completedAt?.toJson(),
    };
  }
}
