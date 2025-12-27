import 'dart:io';

void main() {
  AppLogger.section('New Source Generator');

  // 1. Get Source Name
  stdout.write(
      '${AppLogger.cyan}Enter Source Name (e.g. HiAnime): ${AppLogger.reset}');
  final name = stdin.readLineSync()?.trim();

  if (name == null || name.isEmpty) {
    AppLogger.fail('Source name is required.');
    return;
  }

  // 2. Get Base URL
  stdout.write(
      '${AppLogger.cyan}Enter Base URL (e.g. https://hianime.to): ${AppLogger.reset}');
  final baseUrl = stdin.readLineSync()?.trim();

  if (baseUrl == null || baseUrl.isEmpty) {
    AppLogger.fail('Base URL is required.');
    return;
  }

  final snakeCaseName = _toSnakeCase(name);
  final pascalCaseName = _toPascalCase(name);

  final filePath = 'lib/core/sources/anime/$snakeCaseName.dart';
  final file = File(filePath);

  // 3. Validation
  AppLogger.infoPair('Target Path', filePath);

  if (file.existsSync()) {
    AppLogger.w('File already exists at this path. Operation aborted.');
    return;
  }

  // 4. Creation
  try {
    // Ensure directory exists
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _createProviderFile(filePath, snakeCaseName, pascalCaseName, baseUrl);
    AppLogger.success('Source "$name" created successfully!');
  } catch (e) {
    AppLogger.e('Failed to create source file.', e);
  }
}

void _createProviderFile(
    String filePath, String fileName, String className, String baseUrl) {
  final content = '''
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/models/anime/episode_model.dart';
import 'package:shonenx/core/models/anime/page_model.dart';
import 'package:shonenx/core/models/anime/source_model.dart';
import 'package:shonenx/core/sources/anime/anime_provider.dart';

class ${className}Provider extends AnimeProvider {
  ${className}Provider()
      : super(
            baseUrl: '$baseUrl',
            providerName: '$fileName',
            apiUrl: '');

  @override
  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
      };

  @override
  Future<HomePage> getHome() async {
    final response = await http.get(Uri.parse(baseUrl), headers: headers);
    final document = parse(response.body);
    return _parseHome(document, baseUrl);
  }

  @override
  Future<DetailPage> getDetails(String animeId) async {
    final response =
        await http.get(Uri.parse('\$baseUrl/\$animeId'), headers: headers);
    final document = parse(response.body);
    return _parseDetails(document, baseUrl);
  }

  @override
  Future<BaseEpisodeModel> getEpisodes(String animeId) async {
    final response = await http.get(Uri.parse('\$baseUrl/episodes/\$animeId'),
        headers: headers);
    final document = parse(response.body);
    return _parseEpisodes(document, baseUrl);
  }

  @override
  Future<BaseSourcesModel> getSources(String animeId, String episodeId,
      String? serverName, String? category) async {
    final response = await http.get(Uri.parse('\$baseUrl/watch/\$episodeId'),
        headers: headers);
    return _parseSources(response.body, baseUrl);
  }

  @override
  Future<SearchPage> getSearch(String keyword, String? type, int page) async {
    final response = await http.get(
        Uri.parse('\$baseUrl/search?keyword=\$keyword&page=\$page'),
        headers: headers);
    final document = parse(response.body);
    return _parseSearch(document, baseUrl);
  }

  @override
  Future<SearchPage> getPage(String route, int page) async {
    final response = await http.get(Uri.parse('\$baseUrl/\$route?page=\$page'),
        headers: headers);
    final document = parse(response.body);
    return _parsePage(document, baseUrl);
  }

  @override
  Future<WatchPage> getWatch(String animeId) async {
    throw UnimplementedError();
  }

  @override
  Future<BaseServerModel> getSupportedServers({dynamic metadata}) async {
    return [];
  }

  @override
  bool getDubSubParamSupport() {
    return false;
  }
}

// -----------------------------------------------------------------------------
// Parsing Logic (Manual Configuration Required)
// -----------------------------------------------------------------------------

HomePage _parseHome(Document document, String baseUrl) {
  // TODO: Implement parsing logic
  return HomePage(
    trendingAnime: const [],
    popularAnime: const [],
    recentlyUpdated: const [],
    mostFavoriteAnime: const [],
    mostWatchedAnime: const [],
    topRatedAnime: const [],
  );
}

DetailPage _parseDetails(Document document, String baseUrl) {
  // TODO: Implement parsing logic
  return DetailPage(
    anime: null,
  );
}

BaseEpisodeModel _parseEpisodes(Document document, String baseUrl) {
  // TODO: Implement parsing logic
  return BaseEpisodeModel(
    episodes: const [],
    totalEpisodes: 0,
  );
}

BaseSourcesModel _parseSources(String responseBody, String baseUrl) {
  // TODO: Implement parsing logic
  return BaseSourcesModel(
    sources: const [],
    tracks: const [],
  );
}

SearchPage _parseSearch(Document document, String baseUrl) {
  // TODO: Implement parsing logic
  return SearchPage(
    currentPage: 1,
    hasNextPage: false,
    totalPages: 1,
    results: const [],
  );
}

SearchPage _parsePage(Document document, String baseUrl) {
  // TODO: Implement parsing logic
  return SearchPage(
    currentPage: 1,
    hasNextPage: false,
    totalPages: 1,
    results: const [],
  );
}
''';

  File(filePath).writeAsStringSync(content);
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}')
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .toLowerCase();
}

String _toPascalCase(String input) {
  return input
      .split(RegExp(r'[_\s]+'))
      .map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join('');
}

// -----------------------------------------------------------------------------
// CLI-Compatible AppLogger (Pure Dart, No Flutter)
// -----------------------------------------------------------------------------
class AppLogger {
  // ANSI Colors
  static const String _reset = '\x1B[0m';
  static const String _bold = '\x1B[1m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';
  static const String _blue = '\x1B[34m';

  static String get cyan => _cyan;
  static String get reset => _reset;

  static void section(String title) {
    print('\n$_bold$_cyan=== $title ===$_reset');
  }

  static void infoPair(String key, dynamic value) {
    print('$_blue$key:$_reset $value');
  }

  static void success(String message) {
    print('$_green✓ $message$_reset');
  }

  static void fail(String message) {
    print('$_red✗ $message$_reset');
  }

  static void w(String message) {
    print('$_yellow[WARN] $message$_reset');
  }

  static void e(String message, [Object? error]) {
    print('$_red[ERROR] $message$_reset');
    if (error != null) {
      print('$_red$error$_reset');
    }
  }
}
