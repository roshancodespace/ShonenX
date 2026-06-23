import 'package:isar_community/isar.dart';

part 'cache_entry.g.dart';

@collection
class CacheEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  late List<int> bodyBytes;

  String? etag;
  String? lastModified;

  late DateTime expiry;
}
