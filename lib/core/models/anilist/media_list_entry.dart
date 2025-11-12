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

  /// AniList JSON
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

  /// MAL JSON
  factory MediaListEntry.fromMal(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    return MediaListEntry(
      id: node['id'] as int? ?? 0,
      media: Media.fromMal(node), // <- we assume you added Media.fromMal factory
      status: node['list_status']?['status'] ?? 'UNKNOWN',
      score: (node['list_status']?['score'] as num?)?.toDouble() ?? 0.0,
      progress: node['list_status']?['num_episodes_watched'] as int? ?? 0,
      repeat: node['list_status']?['num_times_rewatched'] as int? ?? 0,
      isPrivate: node['list_status']?['private'] as bool? ?? false,
      notes: node['list_status']?['notes'] ?? '',
      startedAt: node['list_status']?['start_date'] != null
          ? FuzzyDate.fromJson(node['list_status']!['start_date'])
          : null,
      completedAt: node['list_status']?['finish_date'] != null
          ? FuzzyDate.fromJson(node['list_status']!['finish_date'])
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
