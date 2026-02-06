import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core_mangayomi/models/page.dart';
import 'package:shonenx/core_mangayomi/models/source.dart';
import 'package:shonenx/core_mangayomi/models/video.dart';

import 'model/filter.dart';
import 'model/m_manga.dart';
import 'model/m_pages.dart';
import 'model/source_preference.dart';

abstract interface class ExtensionService {
  late Source source;

  ExtensionService(this.source);

  String get sourceBaseUrl;
  bool get supportsLatest;

  Map<String, String> getHeaders();

  Future<MPages> getPopular(int page);

  Future<MPages> getLatestUpdates(int page);

  Future<MPages> search(String query, int page, List<dynamic> filters);

  Future<MManga> getDetail(String url);

  Future<List<PageUrl>> getPageList(String url);

  Future<List<Video>> getVideoList(String url);

  Future<String> getHtmlContent(String name, String url);

  Future<String> cleanHtmlContent(String html);

  FilterList getFilterList();

  List<SourcePreference> getSourcePreferences();

  // ShonenX
  Future<List<ServerData>> getSupportedServers(
    String? animeId,
    String? episodeId,
    String? episodenNumber,
  );

  Future<List<Video>> getVideos(
    String animeId,
    String episodeId,
    String server,
    String? category,
  );

  void dispose();
}
