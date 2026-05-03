import 'package:isar_community/isar.dart';
import 'package:shonenx/shared/models/unified_media.dart';

part 'library_entry.g.dart';

@collection
class LibraryEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String providerId;

  @Index()
  late String title;
  late String cover;
  String? type;
  double? score;
  String? status;
  int? episodes;

  int episodesWatched = 0;
  DateTime addedAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  UnifiedMedia toUnifiedMedia() {
    return UnifiedMedia(
      id: providerId,
      type: MediaType.values.firstWhere((e) => e.name == type),
      providerId: providerId,
      cover: cover,
      title: MediaTitle(english: title),
      status: status,
      episodes: episodes,
    );
  }
}
