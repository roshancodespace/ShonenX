import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;

class Megacloud {
  static const megacloud = {
    'script': "https://megacloud.tv/js/player/a/prod/e1-player.min.js?v=",
    'sources': "https://megacloud.tv/embed-2/ajax/e-1/getSources?id=",
  };

  Future<void> extract({required String videoUrl}) async {
    try {
      // final extractedData = BaseSourcesModel();
      final videoId = videoUrl.split('/').last.split('?')[0];
      log("Extracting video ID: $videoId");
      log("Fetching ${megacloud['sources']}$videoId");
      final response = await http
          .get(Uri.parse('${megacloud['sources']}$videoId'), headers: {
        'Accept': '*/*',
        'X-Requested-With': 'XMLHttpRequest',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36',
        'Referrer': videoUrl,
      });
      log("Response Status Code: ${response.statusCode}", time: DateTime.timestamp());
      final data = response.body;
      log("Response Body: $data");

      if (response.statusCode != 200) {
        log("Error: Failed to load data");
        throw Exception('Failed to load data');
      }
    } catch (e) {
      log(e.toString());
    }
  }
}
