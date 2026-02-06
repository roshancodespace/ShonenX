import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core_mangayomi/eval/interface.dart';
import 'package:shonenx/core_mangayomi/eval/javascript/service.dart';
import 'package:shonenx/core_mangayomi/eval/lib.dart';
import 'package:shonenx/core_mangayomi/models/source.dart';

class PlaygroundService {
  final Source source;
  final AnilistService? anilistService;
  late ExtensionService _service;

  PlaygroundService(this.source, {this.anilistService}) {
    _service = getExtensionService(source, anilistService: anilistService);
  }

  Future<dynamic> runFunction(
    String functionName, [
    List<dynamic>? args,
  ]) async {
    try {
      switch (functionName) {
        case 'getPopular':
          final res = await _service.getPopular(args![0] as int);
          return res.toJson();
        case 'getLatestUpdates':
          final res = await _service.getLatestUpdates(args![0] as int);
          return res.toJson();
        case 'search':
          final query = args![0] as String;
          final page = args[1] as int;
          final filters = args.length > 2 ? args[2] as List : [];
          final res = await _service.search(query, page, filters);
          return res.toJson();
        case 'getDetail':
          final res = await _service.getDetail(args![0] as String);
          return res.toJson();
        case 'getPageList':
          final res = await _service.getPageList(args![0] as String);
          return res.map((e) => e.toJson()).toList();
        case 'getVideoList':
          final res = await _service.getVideoList(args![0] as String);
          return res.map((e) => e.toJson()).toList();
        case 'getSourcePreferences':
          final res = _service.getSourcePreferences();
          return res;
        case 'getSupportedServers':
          final animeId = args?[0] as String?;
          final episodeId = args?[1] as String?;
          final episodeNumber = args?[2] as String?;
          final res = await _service.getSupportedServers(
            animeId,
            episodeId,
            episodeNumber,
          );
          return res.map((e) => e.toJson()).toList();
        case 'getVideos':
          final animeId = args?[0] as String;
          final episodeId = args?[1] as String;
          final server = args?[2] as String;
          final category = args?[3] as String?;
          final res = await _service.getVideos(
            animeId,
            episodeId,
            server,
            category,
          );
          return res.map((e) => e.toJson()).toList();
        default:
          return "Function $functionName not implemented in ExtensionService wrapper";
      }
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    if (_service is JsExtensionService) {
      try {
        (_service as JsExtensionService).runtime.dispose();
      } catch (_) {}
    }
  }
}
