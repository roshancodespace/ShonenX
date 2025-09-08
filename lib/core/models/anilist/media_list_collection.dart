import 'package:shonenx/core/models/anilist/media_list_group.dart';

class MediaListCollection {
  final List<MediaListGroup> lists;

  MediaListCollection({
    required this.lists,
  });

  factory MediaListCollection.fromJson(Map<String, dynamic> json) {
    return MediaListCollection(
      lists: (json['lists'] as List<dynamic>?)
              ?.map((e) => MediaListGroup.fromJson(e as Map<String, dynamic>))
              .toList() 
          ?? [],
    );
  }
}
