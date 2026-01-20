import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce/hive.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/core/services/anime_news_network_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/services/notification_service.dart';

part 'news_provider.g.dart';

@riverpod
AnimeNewsNetworkService animeNewsNetworkService(Ref ref) {
  return AnimeNewsNetworkService();
}

@Riverpod(keepAlive: true)
class News extends _$News {
  bool _mounted = true;
  Timer? _timer;

  @override
  Future<List<UniversalNews>> build() async {
    ref.onDispose(() {
      _mounted = false;
      _timer?.cancel();
    });

    // Start polling every 10 minutes
    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
      _fetchAndUpdate(isBackgroundPoll: true);
    });

    try {
      final box = Hive.box<UniversalNews>('news_cache');
      final cached = box.values.toList();
      if (cached.isNotEmpty) {
        _fetchAndUpdate();
        return cached;
      } else {
        await _fetchAndUpdate();
        return box.values.toList();
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> _fetchAndUpdate({bool isBackgroundPoll = false}) async {
    try {
      final service = ref.read(animeNewsNetworkServiceProvider);
      final freshNews = await service.getNews();

      if (!_mounted) return;

      if (freshNews.isNotEmpty) {
        final readBox = Hive.box<String>('news_read_status');
        final mergedNews = freshNews.map((news) {
          if (news.url != null && readBox.containsKey(news.url)) {
            return news.copyWith(isRead: true);
          }
          return news;
        }).toList();

        // If background poll, check if we actually have *new* unread items to notify implicitly via state change.
        if (isBackgroundPoll) {
          final oldState = state.value ?? [];
          final oldUrls = oldState.map((e) => e.url).toSet();
          final newItems = mergedNews
              .where((e) => !oldUrls.contains(e.url))
              .toList();

          if (newItems.isNotEmpty) {
            final count = newItems.length;
            final message = count == 1
                ? 'New: ${newItems.first.title ?? "Anime News"}'
                : '$count New Anime Articles!';

            await NotificationService().showNewsNotification(
              title: 'ShonenX News',
              body: message,
            );
          }
        }

        final box = Hive.box<UniversalNews>('news_cache');
        await box.clear();
        await box.addAll(mergedNews);

        state = AsyncData(mergedNews);
      }
    } catch (e, st) {
      if (!_mounted) return;
      AppLogger.e('Failed to refresh news (poll: $isBackgroundPoll)', e, st);
      if (!isBackgroundPoll && !state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> markAsRead(UniversalNews news) async {
    if (news.url == null || news.isRead) return;

    final readBox = Hive.box<String>('news_read_status');
    await readBox.put(news.url!, DateTime.now().toIso8601String());

    if (state.hasValue) {
      final currentList = state.value!;
      final updatedList = currentList.map((item) {
        if (item.url == news.url) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();

      state = AsyncData(updatedList);

      final box = Hive.box<UniversalNews>('news_cache');
      await box.clear();
      await box.addAll(updatedList);
    }
  }

  Future<void> refresh() async {
    state = AsyncLoading<List<UniversalNews>>();

    await _fetchAndUpdate();
  }
}
