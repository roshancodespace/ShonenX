import 'package:shonenx/core/models/tracker/tracker_type.dart';

abstract class TrackerService {
  TrackerType get type;

  Future<void> updateEntry({
    required String remoteId,
    String? status,
    int? progress,
    double? score,
    int? repeat,
    String? notes,
    bool? isPrivate,
  });
}
