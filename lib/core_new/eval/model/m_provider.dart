import 'package:shonenx/core_new/eval/model/filter.dart';
import 'package:shonenx/core_new/eval/model/m_manga.dart';
import 'package:shonenx/core_new/eval/model/m_pages.dart';
import 'package:shonenx/core_new/models/video.dart';

abstract class MProvider {
  MProvider();

  bool get supportsLatest => true;

  String? get baseUrl;

  Map<String, String> get headers;

  Future<MPages> getLatestUpdates(int page);

  Future<MPages> getPopular(int page);

  Future<MPages> search(String query, int page, FilterList filterList);

  Future<MManga> getDetail(String url);

  Future<List<dynamic>> getPageList(String url);

  Future<List<Video>> getVideoList(String url);

  Future<String> getHtmlContent(String name, String url);

  Future<String> cleanHtmlContent(String html);

  List<dynamic> getFilterList();

  List<dynamic> getSourcePreferences();
}
