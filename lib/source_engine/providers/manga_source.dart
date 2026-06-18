import 'package:shonenx/source_engine/providers/media_source.dart';

abstract class MangaSource extends MediaSource {
  Future<List<dynamic>> getChapters(String mangaId);
  Future<List<String>> getPages(String chapterId);
}
