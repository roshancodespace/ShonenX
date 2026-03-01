import '../../Extensions/SourceMethods.dart';
import '../../Models/DEpisode.dart';
import '../../Models/DMedia.dart';
import '../../Models/Page.dart';
import '../../Models/Pages.dart';
import '../../Models/Source.dart';
import '../../Models/SourcePreference.dart';
import '../../Models/Video.dart';

class SoraSourceMethods extends SourceMethods {
  @override
  Source source;

  SoraSourceMethods(this.source);
  @override
  Future<DMedia> getDetail(DMedia media) {
    // TODO: implement getDetail
    throw UnimplementedError();
  }

  @override
  Future<Pages> getLatestUpdates(int page) {
    // TODO: implement getLatestUpdates
    throw UnimplementedError();
  }

  @override
  Future<String?> getNovelContent(String chapterTitle, String chapterId) {
    // TODO: implement getNovelContent
    throw UnimplementedError();
  }

  @override
  Future<List<PageUrl>> getPageList(DEpisode episode) {
    // TODO: implement getPageList
    throw UnimplementedError();
  }

  @override
  Future<Pages> getPopular(int page) {
    // TODO: implement getPopular
    throw UnimplementedError();
  }

  @override
  Future<List<SourcePreference>> getPreference() {
    // TODO: implement getPreference
    throw UnimplementedError();
  }

  @override
  Future<List<Video>> getVideoList(DEpisode episode) {
    // TODO: implement getVideoList
    throw UnimplementedError();
  }

  @override
  Future<Pages> search(String query, int page, List<dynamic> filters) {
    // TODO: implement search
    throw UnimplementedError();
  }

  @override
  Future<bool> setPreference(SourcePreference pref, value) {
    // TODO: implement setPreference
    throw UnimplementedError();
  }
}
