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

  static IsarTrackerLink fromBackupMap(Map<String, dynamic> m) =>
      IsarTrackerLink()
        ..primaryMediaId =
            (m['primaryMediaId'] ?? m['mediaId'] ?? m['id'] ?? '').toString()
        ..mappings = (m['mappings'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((mp) => TrackerMapping.fromBackupMap(
                Map<String, dynamic>.from(mp)))
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
    ..trackerId = m['trackerId']?.toString()
    ..trackingId = m['trackingId']?.toString()
    ..trackingTitle = m['trackingTitle']?.toString();
}
