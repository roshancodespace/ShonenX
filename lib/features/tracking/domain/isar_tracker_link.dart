import 'package:isar_community/isar.dart';

part 'isar_tracker_link.g.dart';

@collection
class IsarTrackerLink {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String primaryMediaId;

  List<TrackerMapping> mappings = [];

  Map<String, dynamic> toBackupMap() => {
    'primaryMediaId': primaryMediaId,
    'mappings': mappings.map((m) => m.toBackupMap()).toList(),
  };

  static IsarTrackerLink fromBackupMap(Map<String, dynamic> m) => IsarTrackerLink()
    ..primaryMediaId = m['primaryMediaId'] as String
    ..mappings = (m['mappings'] as List<dynamic>? ?? [])
        .map((mp) => TrackerMapping.fromBackupMap(mp as Map<String, dynamic>))
        .toList();
}

@embedded
class TrackerMapping {
  String? trackerId;
  String? trackingId;
  String? trackingTitle;

  Map<String, dynamic> toBackupMap() => {
    'trackerId': trackerId,
    'trackingId': trackingId,
    'trackingTitle': trackingTitle,
  };

  static TrackerMapping fromBackupMap(Map<String, dynamic> m) => TrackerMapping()
    ..trackerId = m['trackerId'] as String?
    ..trackingId = m['trackingId'] as String?
    ..trackingTitle = m['trackingTitle'] as String?;
}
