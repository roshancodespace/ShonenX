import 'package:isar_community/isar.dart';

part 'media_source_preference.g.dart';

@collection
class MediaSourcePreference {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String mediaTitle;

  late String preferredSourceId;
  late String preferredSourceName;
  late String preferredSourceType;
  String? manualOverrideTitle;
  String? manualOverrideId;
}
