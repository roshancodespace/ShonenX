import 'package:shonenx/core/models/anilist/media_list_entry.dart';
import 'package:shonenx/core/services/mappers/list_entry_mapper.dart';

class MediaListGroup {
  final String name;
  final List<MediaListEntry> entries;

  const MediaListGroup({
    required this.name,
    required this.entries,
  });

  factory MediaListGroup.fromJson(Map<String, dynamic> json) {
    final entriesJson = json['entries'] as List<dynamic>? ?? [];
    return MediaListGroup(
      name: json['name'] as String? ?? 'Unknown',
      entries: entriesJson
          .map((e) => MediaListEntryMapper.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
