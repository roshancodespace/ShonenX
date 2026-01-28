import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/core/services/anime_news_network_service.dart';
import 'package:shonenx/core/services/notification_service.dart';

class NewsBackgroundTask {
  static Future<bool> performUpdate() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);
      
      final cacheBox = await Hive.openBox<UniversalNews>('news_cache');
      final readBox = await Hive.openBox<String>('news_read_status');
      final settingsBox = await Hive.openBox('settings');

      final isAppOpen = settingsBox.get('is_app_open', defaultValue: false);
      if (isAppOpen) return true;

      final service = AnimeNewsNetworkService();
      final freshNews = await service.getNews();

      if (freshNews.isNotEmpty) {
        final oldUrls = cacheBox.values.map((e) => e.url).toSet();
        
        final newItems = freshNews.where((e) => !oldUrls.contains(e.url)).toList();

        if (newItems.isNotEmpty) {
          final count = newItems.length;
          final message = count == 1
              ? 'New: ${newItems.first.title}'
              : '$count New Anime Articles Available!';

          await NotificationService().showNewsNotification(
            title: 'ShonenX News',
            body: message,
          );

          final mergedNews = freshNews.map((news) {
            return news.copyWith(isRead: readBox.containsKey(news.url));
          }).toList();

          await cacheBox.clear();
          await cacheBox.addAll(mergedNews);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}