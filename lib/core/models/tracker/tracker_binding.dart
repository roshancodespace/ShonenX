import 'package:isar_community/isar.dart';
import 'package:shonenx/core/models/tracker/tracker_type.dart';

part 'tracker_binding.g.dart';

@embedded
class TrackerBinding {
  @enumerated
  late TrackerType type;

  String? remoteId;

  TrackerBinding({this.type = TrackerType.anilist, this.remoteId});

  TrackerBinding.fromJson(Map<String, dynamic> json) {
    type = TrackerType.values[json['type'] ?? 0];
    remoteId = json['remoteId'];
  }

  Map<String, dynamic> toJson() => {'type': type.index, 'remoteId': remoteId};
}
