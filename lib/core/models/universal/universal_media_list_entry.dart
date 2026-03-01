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

  factory UniversalMediaListEntry.fromAnilist(Map<String, dynamic> json) {
    return UniversalMediaListEntry(
      id: json['id']?.toString() ?? '0',
      media: UniversalMedia.fromAnilist(json['media'] ?? {}),
      status: json['status'] ?? 'UNKNOWN',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      progress: json['progress'] ?? 0,
      repeat: json['repeat'] ?? 0,
      isPrivate: json['private'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  factory UniversalMediaListEntry.fromMal(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    return UniversalMediaListEntry(
      id: node['id']?.toString() ?? '0',
      media: UniversalMedia.fromMal(node),
      status: _normalizeMalStatus(node['list_status']?['status']),
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

String _normalizeMalStatus(String? status) {
  if (status == null) return 'UNKNOWN';
  switch (status) {
    case 'watching':
      return 'CURRENT';
    case 'completed':
      return 'COMPLETED';
    case 'on_hold':
      return 'PAUSED';
    case 'dropped':
      return 'DROPPED';
    case 'plan_to_watch':
      return 'PLANNING';
    default:
      return status.toUpperCase();
  }
}
