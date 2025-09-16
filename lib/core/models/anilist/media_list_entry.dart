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

  factory MediaListEntry.fromJson(Map<String, dynamic> json) {
    return MediaListEntry(
      id: json['id'] as int? ?? 0,
      media: Media.fromJson(json['media'] ?? {}),
      status: json['status'] as String? ?? 'UNKNOWN',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      progress: json['progress'] as int? ?? 0,
      repeat: json['repeat'] as int? ?? 0,
      isPrivate: json['private'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      startedAt: json['startedAt'] != null
          ? FuzzyDate.fromJson(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? FuzzyDate.fromJson(json['completedAt'])
          : null,
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
