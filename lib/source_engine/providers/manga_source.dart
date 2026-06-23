import 'package:shonenx/shared/models/unified_chapter.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';

abstract class MangaSource extends MediaSource {
  Future<List<UnifiedChapter>> getChapters(String mangaId);
  Future<List<ChapterPage>> getPages(String chapterId);
}