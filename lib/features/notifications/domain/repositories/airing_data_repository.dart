import 'package:shonenx/features/notifications/domain/models/airing_schedule.dart';

abstract class AiringDataRepository {
  Future<List<AiringSchedule>> getAiringSchedule(String mediaId);
}
