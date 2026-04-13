import 'package:shonenx/core/models/universal/universal_media_list_entry.dart';
import 'package:shonenx/core/services/mappers/universal_media_mapper.dart';
import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/services/mappers/media_mapper.dart';

class UniversalMediaListEntryMapper {
  static UniversalMediaListEntry fromAnilist(Map<String, dynamic> json) {
    return UniversalMediaListEntry(
      id: json['id']?.toString() ?? '0',
      media: UniversalMediaMapper.fromAnilist(json['media'] ?? {}),
      status: json['status'] ?? 'UNKNOWN',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      progress: json['progress'] ?? 0,
      repeat: json['repeat'] ?? 0,
      isPrivate: json['private'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  static UniversalMediaListEntry fromMal(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    return UniversalMediaListEntry(
      id: node['id']?.toString() ?? '0',
      media: UniversalMediaMapper.fromMal(node),
      status: _normalizeMalStatus(node['list_status']?['status']),
      score: (node['list_status']?['score'] as num?)?.toDouble() ?? 0.0,
      progress: node['list_status']?['num_episodes_watched'] as int? ?? 0,
      repeat: node['list_status']?['num_times_rewatched'] as int? ?? 0,
      isPrivate: node['list_status']?['private'] as bool? ?? false,
      notes: node['list_status']?['notes'] ?? '',
    );
  }

  static String _normalizeMalStatus(String? status) {
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
}

class MediaListEntryMapper {
  static MediaListEntry fromJson(Map<String, dynamic> json) {
    if (json['media'] == null) {
      return MediaListEntry(
        id: json['id'] as int? ?? 0,
        media: MediaMapper.fromJson(json),
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
    return MediaListEntry(
      id: json['id'] as int? ?? 0,
      media: MediaMapper.fromJson(json['media'] ?? {}),
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

  static MediaListEntry fromMal(Map<String, dynamic> json) {
    final node = json['node'] ?? {};
    return MediaListEntry(
      id: node['id'] as int? ?? 0,
      media: MediaMapper.fromMal(node),
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
}
