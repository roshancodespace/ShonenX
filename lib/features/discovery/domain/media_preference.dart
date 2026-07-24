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
  
  String? matchedMediaTitle;
  String? matchedMediaId;

  String? preferredTracker; 
  String? trackerMediaId;

  // Legacy fields retained for migration
  @Deprecated('Use matchedMediaTitle instead')
  String? manualOverrideTitle;

  @Deprecated('Use matchedMediaId instead')
  String? manualOverrideId;

  @Deprecated('Use preferredTracker instead')
  String? preferredAiringTracker; 

  @Deprecated('Use trackerMediaId instead')
  String? manualAiringTrackerId;
}
