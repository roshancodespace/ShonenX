import 'package:isar_community/isar.dart';
import 'package:shonenx/core/models/tracker/tracker_models.dart';

part 'external_track_binding.g.dart';

@collection
@Name("ExternalTrackBinding")
class ExternalTrackBinding {
  Id? id;

  int? anilistMediaId;

  int? trackerRemoteId;

  @enumerated
  late TrackerType trackerType;

  String? trackerStatus;
  int? trackerProgress;
  double? trackerScore;
  int? startDate;
  int? endDate;
  int? updatedAt;

  ExternalTrackBinding({
    this.id = Isar.autoIncrement,
    this.anilistMediaId,
    this.trackerRemoteId,
    this.trackerType = TrackerType.anilist,
    this.trackerStatus,
    this.trackerProgress,
    this.trackerScore,
    this.startDate,
    this.endDate,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'anilistMediaId': anilistMediaId,
    'trackerRemoteId': trackerRemoteId,
    'trackerType': trackerType.index,
    'trackerStatus': trackerStatus,
    'trackerProgress': trackerProgress,
    'trackerScore': trackerScore,
    'startDate': startDate,
    'endDate': endDate,
    'updatedAt': updatedAt,
  };

  ExternalTrackBinding.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    anilistMediaId = json['anilistMediaId'];
    trackerRemoteId = json['trackerRemoteId'];
    trackerType = TrackerType.values[json['trackerType'] ?? 0];
    trackerStatus = json['trackerStatus'];
    trackerProgress = json['trackerProgress'];
    trackerScore = (json['trackerScore'] as num?)?.toDouble();
    startDate = json['startDate'];
    endDate = json['endDate'];
    updatedAt = json['updatedAt'];
  }
}
