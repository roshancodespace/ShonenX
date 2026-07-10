import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/models/unified_chapter.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';
import 'base_source_adapter.dart';

class MangaSourceAdapter extends BaseSourceAdapter implements MangaSource {
  MangaSourceAdapter({required super.sourceInfo, required super.source});

  @override
  final log = AppLogger.scope(MangaSourceAdapter);

  @override
  Future<List<UnifiedChapter>> getChapters(String mangaId) async {
    final methodLog = log.child('getChapters');
    try {
      final parts = mangaId.split('|');
      final url = parts[0];
      final title = parts.length > 1 ? parts[1] : '';
      methodLog.i('url=$url title=$title');

      final detail = await source.methods.getDetail(
        bridge.DMedia(url: url, title: title),
      );

      methodLog.d('chapters=${detail.episodes?.length ?? 0}');

      return (detail.episodes ?? [])
          .map(
            (e) => UnifiedChapter(
              id: '${e.url!}|${e.episodeNumber}',
              title: e.name,
              number: double.tryParse(e.episodeNumber) ?? 0.0,
              scanlator: e.scanlator,
              uploadDate: e.dateUpload,
            ),
          )
          .toList();
    } catch (e, st) {
      methodLog.e('getChapters failed', e, st);
      return [];
    }
  }

  @override
  Future<List<ChapterPage>> getPages(String chapterId) async {
    final methodLog = log.child('getPages');
    try {
      methodLog.i('chapterId=$chapterId');
      final parts = chapterId.split('|');
      final url = parts[0];
      final epNum = parts.length > 1 ? parts[1] : '1';

      final pages = await source.methods.getPageList(
        bridge.DEpisode(url: url, episodeNumber: epNum),
      );

      methodLog.d('pages=${pages.length}');
      return pages.map((e) {
        final finalHeaders = <String, String>{}
          ..addAll({
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36',
            'Referer': sourceInfo.baseUrl ?? '',
          });

        return ChapterPage(url: e.url, headers: finalHeaders);
      }).toList();
    } catch (e, st) {
      methodLog.e('getPages failed', e, st);
      return [];
    }
  }

  @override
  Future<List<String>> getFilterGenres() async {
    return [];
  }

  @override
  Future<List<String>> getFilterTags() async {
    return [];
  }
}
