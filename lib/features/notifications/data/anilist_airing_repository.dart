import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/notifications/domain/models/airing_schedule.dart';
import 'package:shonenx/features/notifications/data/airing_data_repository.dart';

class AniListAiringRepository implements AiringDataRepository {
  final HTTP _http;
  final String _endpoint = 'https://graphql.anilist.co';

  AniListAiringRepository(this._http);

  @override
  Future<List<AiringSchedule>> getAiringSchedule(String mediaId) async {
    final id = int.tryParse(mediaId);
    if (id == null) return [];

    const query = '''
      query (\$id: Int) {
        Media(id: \$id) {
          airingSchedule(notYetAired: true) {
            nodes {
              episode
              airingAt
            }
          }
        }
      }
    ''';

    try {
      final response = await _http.post(
        _endpoint,
        body: {
          'query': query,
          'variables': {'id': id},
        },
        cacheDuration: const Duration(hours: 1),
      );

      final data = response.json['data'] as Map?;
      if (data == null) return [];

      final nodes = (data['Media']?['airingSchedule']?['nodes'] as List?) ?? [];

      final schedules = <AiringSchedule>[];
      for (final node in nodes) {
        if (node is Map) {
          final episode = node['episode'] as int?;
          final airingAtTimestamp = node['airingAt'] as int?;

          if (episode != null && airingAtTimestamp != null) {
            schedules.add(
              AiringSchedule(
                episode: episode,
                airingAt: DateTime.fromMillisecondsSinceEpoch(
                  airingAtTimestamp * 1000,
                ),
              ),
            );
          }
        }
      }

      // Sort by episode to be safe
      schedules.sort((a, b) => a.episode.compareTo(b.episode));
      return schedules;
    } catch (e) {
      return [];
    }
  }
}
