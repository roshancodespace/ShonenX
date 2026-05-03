import 'package:isar_community/isar.dart';

part 'isar_tracker_link.g.dart';

@collection
class IsarTrackerLink {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String primaryMediaId;

  List<TrackerMapping> mappings = [];
}

@embedded
class TrackerMapping {
  String? trackerId;
  String? trackingId;
  String? trackingTitle;
}
