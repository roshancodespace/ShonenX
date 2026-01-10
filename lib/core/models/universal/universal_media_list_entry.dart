import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';

class UniversalMediaListEntry {
  final String id;
  final UniversalMedia media;
  final String status;
  final double score;
  final int progress;
  final int repeat;
  final bool isPrivate;
  final String notes;

  const UniversalMediaListEntry({
    required this.id,
    required this.media,
    required this.status,
    required this.score,
    required this.progress,
    required this.repeat,
    required this.isPrivate,
    required this.notes,
  });

  factory UniversalMediaListEntry.fromAnilist(MediaListEntry entry) {
    return UniversalMediaListEntry(
      id: entry.id.toString(),
      media: UniversalMedia.fromAnilist(entry.media),
      status: entry.status,
      score: entry.score,
      progress: entry.progress,
      repeat: entry.repeat,
      isPrivate: entry.isPrivate,
      notes: entry.notes,
    );
  }

  factory UniversalMediaListEntry.fromMal(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    return UniversalMediaListEntry(
      id: node['id']?.toString() ?? '0',
      media: UniversalMedia.fromMal(node),
      status: node['list_status']?['status'] ?? 'UNKNOWN',
      score: (node['list_status']?['score'] as num?)?.toDouble() ?? 0.0,
      progress: node['list_status']?['num_episodes_watched'] as int? ?? 0,
      repeat: node['list_status']?['num_times_rewatched'] as int? ?? 0,
      isPrivate: node['list_status']?['private'] as bool? ?? false,
      notes: node['list_status']?['notes'] ?? '',
    );
  }

  UniversalMediaListEntry copyWith({
    String? id,
    UniversalMedia? media,
    String? status,
    double? score,
    int? progress,
    int? repeat,
    bool? isPrivate,
    String? notes,
  }) {
    return UniversalMediaListEntry(
      id: id ?? this.id,
      media: media ?? this.media,
      status: status ?? this.status,
      score: score ?? this.score,
      progress: progress ?? this.progress,
      repeat: repeat ?? this.repeat,
      isPrivate: isPrivate ?? this.isPrivate,
      notes: notes ?? this.notes,
    );
  }
}
