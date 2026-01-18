import 'package:html/parser.dart' as html;
import 'package:shonenx/core/network/universal_client.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';

class AnimeNewsNetworkService {
  static const String _baseUrl = 'https://animenewsnetwork.com';
  static const String _cdnUrl = 'https://cdn.animenewsnetwork.com';

  final UniversalHttpClient _client = UniversalHttpClient.instance;

  Future<String> _fetch(String url) async {
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load news page: ${res.statusCode}');
    }
    return res.body;
  }

  Future<List<UniversalNews>> getNews() async {
    try {
      final url = '$_baseUrl/news';
      final htmlBody = await _fetch(url);
      final document = html.parse(htmlBody);
      final List<UniversalNews> newsList = [];

      document.querySelectorAll('.herald.box.news.t-news').forEach((element) {
        final src = element.querySelector('.thumbnail')?.attributes['data-src'];
        var image = src != null ? _cdnUrl + src : null;

        final wrapDiv = element.querySelector('.wrap > div');
        final titleElement = wrapDiv?.querySelector('h3')?.children.firstOrNull;

        final href = titleElement?.attributes['href'];
        final ref = href != null ? _baseUrl + href : null;

        final title = titleElement?.text.trim();

        final dateAndTime = wrapDiv
            ?.querySelector('time')
            ?.attributes['datetime'];
        String? date;
        if (dateAndTime != null) {
          try {
            final dt = DateTime.parse(dateAndTime);
            date =
                "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
          } catch (_) {
            date = dateAndTime;
          }
        }

        final snippet = wrapDiv?.querySelector('.snippet > span.full')?.text;

        if (title != null && ref != null) {
          newsList.add(
            UniversalNews(
              title: title,
              url: ref,
              imageUrl: image,
              date: date,
              excerpt: snippet,
            ),
          );
        }
      });

      return newsList;
    } catch (e) {
      return [];
    }
  }

  Future<UniversalNews?> getDetailedNews(UniversalNews news) async {
    if (news.url == null) return news;
    try {
      final htmlBody = await _fetch(news.url!);
      final document = html.parse(htmlBody);

      final details = document.querySelector(
        'div.text-zone.easyread-width > div.KonaBody > div.meat',
      );

      final List<String> texts = [];
      details?.children.forEach((element) {
        if (element.localName == 'p') {
          texts.add(element.text.trim());
          texts.add('\n\n');
        } else {
          texts.add(element.text.trim());
          texts.add('\n');
        }
      });

      final fullInfo = texts.join();

      return UniversalNews(
        title: news.title,
        url: news.url,
        imageUrl: news.imageUrl,
        date: news.date,
        excerpt: news.excerpt,
        body: fullInfo,
      );
    } catch (e) {
      return news;
    }
  }
}
