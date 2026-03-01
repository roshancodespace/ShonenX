import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:isar_community/isar.dart';
import 'package:shonenx/core/models/tracker/tracker_binding.dart';

part 'track.g.dart';

@collection
@Name("Track")
class Track {
  Id? id;

  String? mediaId;

  String? title;

  int? progress;

  int? total;

  int? score;

  @enumerated
  late TrackStatus status;

  int? startedAt;

  int? completedAt;

  @enumerated
  late ItemType itemType;

  int? updatedAt;

  List<TrackerBinding>? bindings;

  Track({
    this.id = Isar.autoIncrement,
    this.mediaId,
    this.title,
    this.progress,
    this.total,
    this.score,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.itemType = ItemType.anime,
    this.updatedAt = 0,
    this.bindings,
  });
  Track.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    mediaId = json['mediaId'];
    score = json['score'];
    startedAt = json['startedAt'];
    completedAt = json['completedAt'];
    progress = json['progress'];
    status = TrackStatus.values[json['status']];
    title = json['title'];
    total = json['total'];
    itemType = ItemType.values[json['itemType']];
    updatedAt = json['updatedAt'];
    if (json['bindings'] != null) {
      bindings = (json['bindings'] as List)
          .map((e) => TrackerBinding.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaId': mediaId,
    'score': score,
    'completedAt': completedAt,
    'progress': progress,
    'startedAt': startedAt,
    'status': status.index,
    'title': title,
    'total': total,
    'itemType': itemType.index,
    'updatedAt': updatedAt ?? 0,
    'bindings': bindings?.map((e) => e.toJson()).toList(),
  };
}

enum TrackStatus {
  reading,
  completed,
  onHold,
  dropped,
  planToRead,
  reReading,
  watching,
  planToWatch,
  reWatching,
}
