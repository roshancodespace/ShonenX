import 'package:isar_community/isar.dart';

part 'media_preference.g.dart';

@collection
class MediaPreference {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String mediaTitle;

  late String preferredSourceId;
  late String preferredSourceName;
  late String preferredSourceType;
  
  String? manualOverrideTitle;
  String? manualOverrideId;

  String? preferredAiringTracker; 
  String? manualAiringTrackerId;
}
