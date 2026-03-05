import 'package:isar_community/isar.dart';

part 'isar_source_preference.g.dart';

@collection
class IsarSourcePreference {
  Id? id;

  @Index(unique: true, replace: true)
  late String animeId;

  String? sourceId;
  String? sourceType; // 'legacy', 'mangayomi', 'aniyomi'
  String? matchedAnimeId;
  String? matchedAnimeTitle;
  String? animeCover;

  IsarSourcePreference({
    this.id,
    required this.animeId,
    this.sourceId,
    this.sourceType,
    this.matchedAnimeId,
    this.matchedAnimeTitle,
    this.animeCover,
  });
}
