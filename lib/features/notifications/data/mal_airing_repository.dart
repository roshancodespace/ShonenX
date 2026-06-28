import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/notifications/domain/models/airing_schedule.dart';
import 'package:shonenx/features/notifications/data/airing_data_repository.dart';
import 'package:shonenx/features/tracking/engine/trackers/mal/mal_metadata.dart';

class MALAiringRepository implements AiringDataRepository {
  final HTTP _http;

  MALAiringRepository(this._http);

  @override
  Future<List<AiringSchedule>> getAiringSchedule(String mediaId) async {
    final id = int.tryParse(mediaId);
    if (id == null) return [];

    try {
      final response = await _http.get(
        'https://api.myanimelist.net/v2/anime/$id',
        queryParameters: {'fields': 'broadcast,start_date,status,num_episodes'},
        headers: {'X-MAL-CLIENT-ID': MalMetadata.clientId},
        cacheDuration: const Duration(hours: 1),
      );

      final json = response.json;
      if (json['error'] != null || json['status'] != 'currently_airing' || json['broadcast'] is! Map) {
        return [];
      }

      final broadcast = json['broadcast'] as Map;
      final dayString = broadcast['day_of_the_week']?.toString().toLowerCase().trim();
      final timeString = broadcast['start_time']?.toString().trim();

      final Map<String, int> weekdayMap = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };

      final targetWeekday = weekdayMap[dayString];
      if (targetWeekday != null && timeString != null && timeString.contains(':')) {
        final parts = timeString.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null && minute != null) {
          final nowUtc = DateTime.now().toUtc();
          final nowJst = nowUtc.add(const Duration(hours: 9));

          final candidateJst = DateTime(
            nowJst.year,
            nowJst.month,
            nowJst.day,
            hour,
            minute,
          );
          
          var daysDiff = targetWeekday - nowJst.weekday;
          if (daysDiff < 0 || (daysDiff == 0 && nowJst.isAfter(candidateJst))) {
            daysDiff += 7;
          }

          final airingTimeJst = candidateJst.add(Duration(days: daysDiff));
          final airingAt = airingTimeJst.subtract(const Duration(hours: 9)).toLocal();

          int? nextEpisode;
          final startDateStr = json['start_date'] as String?;
          if (startDateStr != null) {
            final startDate = DateTime.tryParse(startDateStr);
            if (startDate != null) {
              final diffDays = airingTimeJst.difference(startDate).inDays;
              if (diffDays >= 0) {
                final episodes = json['num_episodes'] as int?;
                final calculatedEp = (diffDays / 7).floor() + 1;
                if (episodes == null || calculatedEp <= episodes) {
                  nextEpisode = calculatedEp;
                }
              }
            }
          }

          if (nextEpisode != null) {
            return [
              AiringSchedule(episode: nextEpisode, airingAt: airingAt),
            ];
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
