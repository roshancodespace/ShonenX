import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:shonenx/core/models/anime/server_model.dart';
import 'package:shonenx/core/registery/anime_source_registery.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/utils/extractors.dart' as extractor;

// ==========================================
// 🔧 CONFIGURATION
// ==========================================
const debugConfig = DebugConfig(
  provider: 'gojo',
  searchQuery: 'one piece',
  useCache: true,
  resetCache: false,
  manualServerIndex: 1,
  manualEpiosodeIndex: 1,
);
// ==========================================

/* ============================================================
 * DEBUG CONFIG / CONTEXT
 * ============================================================ */
class DebugConfig {
  final String provider;
  final String searchQuery;
  final int manualServerIndex;
  final int manualEpiosodeIndex;
  final bool useCache;
  final bool resetCache;
  final int maxResultsToPrint;
  final bool verifyStreams;
  final bool failFast;
  final Duration requestTimeout;
  final int retryAttempts;
  final Duration retryDelay;

  const DebugConfig({
    required this.provider,
    required this.searchQuery,
    this.manualServerIndex = 0,
    this.manualEpiosodeIndex = 0,
    this.useCache = true,
    this.resetCache = false,
    this.maxResultsToPrint = 5,
    this.verifyStreams = true,
    this.failFast = true,
    this.requestTimeout = const Duration(seconds: 20),
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 2),
  });
}

class DebugContext {
  late final dynamic provider;
  dynamic searchResult;
  dynamic episodeResult;
  dynamic selectedAnime;
  dynamic selectedEpisode;
  BaseServerModel? servers;
  dynamic sourcesResult;
  dynamic selectedServer;
}

/* ============================================================
 * CACHE
 * ============================================================ */
class CacheManager {
  static final File _file = File('.debug_cache');

  static Future<Map<String, dynamic>?> load() async {
    if (!debugConfig.useCache) return null;

    if (debugConfig.resetCache) {
      if (await _file.exists()) await _file.delete();
      return null;
    }

    if (await _file.exists()) {
      try {
        final data = jsonDecode(await _file.readAsString());
        if (data['provider'] == debugConfig.provider &&
            data['query'] == debugConfig.searchQuery) {
          return data;
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<void> save(
    String animeId,
    String animeName,
    String epId,
    String epNumber,
  ) async {
    if (!debugConfig.useCache) return;

    await _file.writeAsString(
      jsonEncode({
        'provider': debugConfig.provider,
        'query': debugConfig.searchQuery,
        'animeId': animeId,
        'animeName': animeName,
        'epId': epId,
        'epNumber': epNumber,
      }),
    );
  }
}

class CachedObj {
  final String id;
  final String name;
  final dynamic number;
  CachedObj(this.id, this.name, [this.number]);
}

/* ============================================================
 * HELPERS
 * ============================================================ */
Future<void> runStep(
  String title,
  Future<void> Function() action, {
  bool failFast = true,
}) async {
  final sw = Stopwatch()..start();
  AppLogger.section(title);

  try {
    await action();
    sw.stop();
    AppLogger.success('$title ✓ (${sw.elapsedMilliseconds} ms)');
  } catch (e, st) {
    sw.stop();
    AppLogger.fail('$title ✗ (${sw.elapsedMilliseconds} ms)');
    AppLogger.e(e, e, st);
    if (failFast) rethrow;
  }
}

Future<T> retry<T>(
  Future<T> Function() fn, {
  int attempts = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  for (var i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (_) {
      if (i == attempts - 1) rethrow;
      await Future.delayed(delay);
    }
  }
  throw StateError('Unreachable');
}

/* ============================================================
 * MAIN
 * ============================================================ */
Future<void> main() async {
  HttpOverrides.global = null;

  final ctx = DebugContext();
  final cache = await CacheManager.load();

  try {
    await runStep('INITIALIZATION', () async {
      final registry = AnimeSourceRegistry();
      ctx.provider = registry.get(debugConfig.provider);

      if (ctx.provider == null) {
        throw StateError('Provider not found: ${debugConfig.provider}');
      }

      if (cache != null) {
        AppLogger.success('⚡ CACHE LOADED');
        AppLogger.infoPair('Anime', cache['animeName']);
        AppLogger.infoPair('Episode', cache['epNumber']);
      }
    });

    if (cache != null) {
      ctx.selectedAnime = CachedObj(cache['animeId'], cache['animeName']);
      ctx.selectedEpisode = CachedObj(cache['epId'], '', cache['epNumber']);
    } else {
      await runStep('SEARCH', () async {
        ctx.searchResult = await retry(
          () => ctx.provider.getSearch(debugConfig.searchQuery, null, 1),
          attempts: debugConfig.retryAttempts,
        );

        ctx.selectedAnime = ctx.searchResult.results.first;
        AppLogger.success('Auto-selected: ${ctx.selectedAnime.name}');
      });

      await runStep('EPISODES', () async {
        ctx.episodeResult = await retry(
          () => ctx.provider.getEpisodes(ctx.selectedAnime.id),
          attempts: debugConfig.retryAttempts,
        );

        ctx.selectedEpisode =
            ctx.episodeResult.episodes[debugConfig.manualEpiosodeIndex];
        AppLogger.infoPair('Episode', ctx.selectedEpisode.number);

        await CacheManager.save(
          ctx.selectedAnime.id,
          ctx.selectedAnime.name,
          ctx.selectedEpisode.id,
          ctx.selectedEpisode.number.toString(),
        );
      });
    }

    await runStep('SERVERS', () async {
      ctx.servers = await retry(
        () => ctx.provider.getSupportedServers(
          metadata: {
            'id': ctx.selectedAnime.id,
            'epId': ctx.selectedEpisode.id,
            'epNumber': ctx.selectedEpisode.number,
          },
        ),
      );

      final servers = ctx.servers?.flatten() ?? [];

      if (servers.isEmpty) {
        AppLogger.raw('No servers found.');
        return;
      }

      for (var i = 0; i < servers.length; i++) {
        final s = servers[i];
        AppLogger.raw(
          '[$i] ${s.name} (${s.id}) ${s.isDub ? "[DUB]" : "[SUB]"}',
        );
      }

      final index = debugConfig.manualServerIndex.clamp(0, servers.length - 1);
      ctx.selectedServer = servers[index];

      AppLogger.success('SELECTED SERVER: ${ctx.selectedServer.name}');
    });

    await runStep('SOURCES', () async {
      ctx.sourcesResult = await retry(
        () => ctx.provider.getSources(
          ctx.selectedAnime.id,
          ctx.selectedEpisode.id,
          ctx.selectedServer?.id,
          ctx.selectedServer?.isDub == true ? 'dub' : 'sub',
        ),
      );

      for (final s in ctx.sourcesResult.sources) {
        AppLogger.raw('${s.quality.padRight(6)} | ${s.url}');
      }

      await extractor.extractQualities(
        ctx.sourcesResult.sources.first.url,
        ctx.sourcesResult.headers.cast<String, String>(),
      );
    });

    if (debugConfig.verifyStreams) {
      await runStep('STREAM HEALTH CHECK', () async {
        for (final source in ctx.sourcesResult.sources) {
          AppLogger.raw('Testing [${source.quality}]...');
          final res = await http
              .get(
                Uri.parse(source.url),
                headers: {
                  ...ctx.sourcesResult.headers.cast<String, String>(),
                  'Range': 'bytes=0-1024',
                },
              )
              .timeout(debugConfig.requestTimeout);

          if (res.statusCode < 400) {
            AppLogger.success('OK ${res.statusCode}');
          } else {
            AppLogger.fail('FAIL ${res.statusCode}');
          }
        }
      }, failFast: false);
    }
  } catch (e, st) {
    AppLogger.e('Fatal error', e, st);
    exitCode = 1;
  }
}
