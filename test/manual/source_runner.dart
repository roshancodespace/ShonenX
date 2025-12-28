import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/registery/anime_source_registery.dart';
import 'package:shonenx/core/utils/app_logger.dart';

// --- CONFIGURATION ---
// ignore: prefer_const_declarations
final String targetProvider = 'gojo';
// ignore: prefer_const_declarations
final String searchQuery = 'one piece';
// ---------------------

void main() {
  test('Manual Source Debugger', () async {
    AppLogger.section('INITIALIZATION');

    // 1. Load Environment Variables
    try {
      await dotenv.load(fileName: ".env");
      AppLogger.success('Loaded .env file');
    } catch (e) {
      AppLogger.raw(
          '${AppLogger.yellow}⚠ .env file not found or failed to load. (Expected if not using .env dependent providers)${AppLogger.reset}');
    }

    // 2. Initialize Registry
    final registry = AnimeSourceRegistry().initialize();
    AppLogger.infoPair('Available Providers', registry.keys.join(', '));
    AppLogger.infoPair('Target Provider', targetProvider);

    final provider = registry.get(targetProvider);
    if (provider == null) {
      AppLogger.fail('Provider "$targetProvider" not found in registry.');
      return;
    }
    AppLogger.success('Provider loaded successfully: ${provider.providerName}');
    AppLogger.infoPair('Base URL', provider.baseUrl);

    // 3. Search
    AppLogger.section('STEP 1: SEARCH');
    AppLogger.infoPair('Query', searchQuery);

    try {
      final searchResult = await provider.getSearch(searchQuery, null, 1);

      if (searchResult.results.isEmpty) {
        AppLogger.fail('No results found for query: "$searchQuery"');
        return;
      }

      AppLogger.success('Found ${searchResult.results.length} results');

      AppLogger.raw(
          '\n${AppLogger.bold}${'INDEX'.padRight(6)} ${'ID'.padRight(20)} NAME${AppLogger.reset}');
      AppLogger.raw('-' * 60);
      for (var i = 0; i < searchResult.results.length.clamp(0, 5); i++) {
        final item = searchResult.results[i];
        AppLogger.raw(
            '${(i + 1).toString().padRight(6)} ${item.id.toString().padRight(20)} ${item.name}');
      }

      final selectedAnime = searchResult.results.first;
      AppLogger.raw(
          '\n${AppLogger.green}➔ Selecting first result: ${selectedAnime.name} (ID: ${selectedAnime.id})${AppLogger.reset}');

      // 4. Episodes
      AppLogger.section('STEP 2: EPISODES');
      final episodeResult = await provider.getEpisodes(selectedAnime.id!);

      if (episodeResult.episodes == null || episodeResult.episodes!.isEmpty) {
        AppLogger.fail('No episodes found for this anime.');
        return;
      }

      final episodes = episodeResult.episodes!;
      AppLogger.success('Found ${episodes.length} episodes');
      AppLogger.infoPair('First Episode',
          'Ep ${episodes.first.number} - ${episodes.first.title}');
      AppLogger.infoPair('Last Episode',
          'Ep ${episodes.last.number} - ${episodes.last.title}');

      // Select first episode
      final selectedEpisode = episodes.first;
      AppLogger.raw(
          '\n${AppLogger.green}➔ Selecting first episode: Ep ${selectedEpisode.number} (ID: ${selectedEpisode.id})${AppLogger.reset}');

      // 5. Servers
      AppLogger.section('STEP 3: SERVERS');
      // Some providers might throw or return empty if they don't support explicit servers
      BaseServerModel servers = BaseServerModel(dub: [], sub: []);

      try {
        servers = await provider.getSupportedServers(metadata: {
          'id': selectedAnime.id,
          'epNumber': selectedEpisode.number,
          'epId': selectedEpisode.id,
        });

        final allServers = [...servers.dub, ...servers.sub];

        AppLogger.infoPair(
          'Supported Servers',
          allServers.isEmpty
              ? 'Default/None'
              : allServers
                  .map(
                      (s) => '${s.id} (${s.name}) - ${s.isDub ? 'Dub' : 'Sub'}')
                  .join(', '),
        );
      } catch (e) {
        AppLogger.raw(
          '${AppLogger.yellow}⚠ Failed to fetch servers (might not be supported): $e${AppLogger.reset}',
        );
      }

      String? selectedServer =
          servers.flatten().isNotEmpty ? servers.flatten().first.id : null;

      // 6. Sources
      AppLogger.section('STEP 4: SOURCES');
      AppLogger.infoPair('Fetching sources for',
          '${selectedAnime.name} - Ep ${selectedEpisode.number}');

      final sourcesResult = await provider.getSources(
          selectedAnime.id!, selectedEpisode.id!, selectedServer, null);

      if (sourcesResult.sources.isEmpty) {
        AppLogger.fail('No stream sources found.');
      } else {
        AppLogger.success(
            'Found ${sourcesResult.sources.length} sources and ${sourcesResult.tracks.length} subtitle tracks');

        AppLogger.raw(
            '\n${AppLogger.bold}--- VIDEO STREAMS ---${AppLogger.reset}');
        for (var source in sourcesResult.sources) {
          AppLogger.raw(
              '${AppLogger.blue}[${source.quality}] ${AppLogger.reset}${source.url}');
        }

        if (sourcesResult.tracks.isNotEmpty) {
          AppLogger.raw(
              '\n${AppLogger.bold}--- SUBTITLES ---${AppLogger.reset}');
          for (var track in sourcesResult.tracks) {
            AppLogger.raw(
                '${AppLogger.yellow}[${track.lang}] ${AppLogger.reset}${track.url}');
          }
        }

        // 7. Verify Streams
        AppLogger.section('STEP 5: VERIFYING STREAMS (HEALTH CHECK)');
        AppLogger.infoPair('Testing connection to',
            '${sourcesResult.sources.length} sources...');

        for (var source in sourcesResult.sources) {
          AppLogger.raw('\nTesting [${source.quality}]...');
          try {
            final uri = Uri.parse(source.url!);
            final headers =
                (sourcesResult.headers as Map?)?.cast<String, String>() ?? {};

            // Simple GET request with range to avoid full download
            // Some servers might not support HEAD or Range, but most video servers do.
            final response = await http.get(uri, headers: {
              ...headers,
              'Range': 'bytes=0-1024', // Request first 1KB
            }).timeout(const Duration(seconds: 10));

            if (response.statusCode >= 200 && response.statusCode < 300) {
              AppLogger.success('Connection OK (Sub-300)');
              AppLogger.infoPair('Status Code', response.statusCode);
              AppLogger.infoPair('Content-Type',
                  '${response.headers['content-type'] ?? 'Unknown'}');
              AppLogger.infoPair('Content-Length',
                  '${response.headers['content-length'] ?? 'Unknown'}');

              if (source.isM3U8) {
                if (response.body.contains('#EXTM3U')) {
                  AppLogger.success('Valid M3U8 Manifest header detected');
                } else {
                  AppLogger.raw(
                      '${AppLogger.yellow}⚠ Warning: content-type suggests M3U8 but content does not start with #EXTM3U${AppLogger.reset}');
                }
              }
            } else {
              AppLogger.fail(
                  'Connection Failed. Status: ${response.statusCode}');
              AppLogger.raw(
                  '${AppLogger.red}Response Body Preview: ${response.body.substring(0, response.body.length.clamp(0, 200))}${AppLogger.reset}');
            }
          } catch (e) {
            AppLogger.fail('Connection Error: $e');
          }
        }
      }
    } catch (e, stack) {
      AppLogger.section('EXCEPTION CAUGHT');
      AppLogger.fail('An error occurred during execution:');
      AppLogger.e(e, e, stack); // Use standard error logging for stack trace
    }

    AppLogger.section('FINISHED');
  });
}
