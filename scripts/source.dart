#!/usr/bin/env dart
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty || (!args.contains('-c') && !args.contains('--create'))) {
    printUsage();
    exit(1);
  }

  int index = args.indexOf('-c');
  if (index == -1) index = args.indexOf('--create');

  if (index + 1 >= args.length) {
    print('❌ Error: Missing <type>:<name> argument after creation flag.');
    printUsage();
    exit(1);
  }

  final target = args[index + 1];
  if (!target.contains(':')) {
    print('❌ Error: Target must be formatted as <type>:<name> (e.g., anime:animepahe)');
    exit(1);
  }

  final parts = target.split(':');
  final type = parts[0].trim().toLowerCase();
  final rawName = parts[1].trim().toLowerCase();

  if (rawName.isEmpty) {
    print('❌ Error: Source name cannot be empty.');
    exit(1);
  }

  final projectRoot = findProjectRoot();
  final targetDir = Directory('${projectRoot.path}/lib/source_engine/inbuilt_sources/$type');

  if (!targetDir.existsSync()) {
    print('📁 Creating directory: ${targetDir.path}');
    targetDir.createSync(recursive: true);
  }

  final fileName = '${rawName.replaceAll('-', '_')}_source.dart';
  final targetFile = File('${targetDir.path}/$fileName');

  if (targetFile.existsSync()) {
    print('⚠️ Warning: File $fileName already exists at ${targetFile.path}');
    stdout.write('Overwrite? (y/N): ');
    final response = stdin.readLineSync()?.trim().toLowerCase();
    if (response != 'y' && response != 'yes') {
      print('Aborted.');
      exit(0);
    }
  }

  final className = formatClassName(rawName);
  final displayName = formatDisplayName(rawName);

  print('⚡ Generating boilerplate for $className...');

  final content = generateBoilerplate(
    type: type,
    sourceId: rawName,
    className: className,
    displayName: displayName,
  );

  targetFile.writeAsStringSync(content);
  print('✅ Successfully created $fileName at:');
  print('   ${targetFile.path}');
}

void printUsage() {
  print('ShonenX Source Boilerplate Generator');
  print('Usage: ./scripts/source.dart -c|--create <type>:<source_name>');
  print('Example: ./scripts/source.dart -c anime:animepahe');
}

Directory findProjectRoot() {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current;
    }
    dir = parent;
  }
  return dir;
}

String formatClassName(String rawName) {
  final words = rawName.split(RegExp(r'[-_ ]+'));
  final pascal = words.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join('');
  if (pascal.toLowerCase().endsWith('source')) {
    return pascal;
  }
  return '${pascal}Source';
}

String formatDisplayName(String rawName) {
  final words = rawName.split(RegExp(r'[-_ ]+'));
  return words.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

String generateBoilerplate({
  required String type,
  required String sourceId,
  required String className,
  required String displayName,
}) {
  if (type == 'manga') {
    // Basic fallback for manga if requested in future
    return '''import 'package:shonenx/shared/models/unified_chapter.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/manga_source.dart';

class $className implements MangaSource {
  @override
  SourceInfo get sourceInfo => const SourceInfo(
        id: '$sourceId',
        name: '$displayName',
        type: SourceType.inbuilt,
        mediaType: MediaType.MANGA,
      );

  @override
  Future<List<SourceSetting>> getSettingsSchema() async => [];

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async => [];

  @override
  Future<List<UnifiedMedia>> search(String query, MediaType type, {int page = 1, bool isAdult = false, List<String> sort = const ['SEARCH_MATCH']}) async => [];

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async => UnifiedMedia(id: providerId, type: MediaType.MANGA, title: const MediaTitle(english: '$displayName Manga'));

  @override
  Future<List<UnifiedChapter>> getChapters(String mangaId) async => [];

  @override
  Future<List<ChapterPage>> getPages(String chapterId) async => [];
}
''';
  }

  return '''import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/anime_source.dart';

class $className implements AnimeSource {
  @override
  SourceInfo get sourceInfo => const SourceInfo(
        id: '$sourceId',
        name: '$displayName',
        type: SourceType.inbuilt,
        mediaType: MediaType.ANIME,
      );

  @override
  Future<List<SourceSetting>> getSettingsSchema() async {
    return [
      const SourceSetting(
        id: 'preferred_quality',
        name: 'Preferred Quality',
        description: 'Default video quality to select',
        type: SettingType.select,
        options: ['Auto', '1080p', '720p', '480p'],
        defaultValue: 'Auto',
      ),
    ];
  }

  @override
  Future<List<UnifiedMedia>> getTrending({int page = 1}) async {
    return [
      UnifiedMedia(
        id: '${sourceId}_trending_1',
        type: MediaType.ANIME,
        sourceId: '$sourceId',
        providerId: '${sourceId}_trending_1',
        title: const MediaTitle(english: '$displayName Trending Demo'),
        cover: 'https://via.placeholder.com/300x450.png?text=$displayName+Trending',
        status: 'Airing',
      ),
    ];
  }

  @override
  Future<List<UnifiedMedia>> search(
    String query,
    MediaType type, {
    int page = 1,
    bool isAdult = false,
    List<String> sort = const ['SEARCH_MATCH'],
  }) async {
    return [
      UnifiedMedia(
        id: '${sourceId}_search_1',
        type: MediaType.ANIME,
        sourceId: '$sourceId',
        providerId: '${sourceId}_search_1',
        title: MediaTitle(english: '$displayName Result: \$query'),
        cover: 'https://via.placeholder.com/300x450.png?text=Search+Result',
        status: 'Completed',
      ),
    ];
  }

  @override
  Future<UnifiedMedia> getDetails(String providerId, MediaType type) async {
    return UnifiedMedia(
      id: providerId,
      type: MediaType.ANIME,
      sourceId: '$sourceId',
      providerId: providerId,
      title: const MediaTitle(english: '$displayName Demo Details'),
      description: 'Demo description generated by boilerplate script for $displayName.',
      episodes: 12,
      status: 'Completed',
    );
  }

  @override
  Future<List<UnifiedEpisode>> getEpisodes(String animeId) async {
    return [
      UnifiedEpisode(
        id: '\$animeId||ep_1',
        number: 1,
        title: 'Episode 1: Demo Beginning',
        thumbnailUrl: 'https://via.placeholder.com/640x360.png?text=Ep+1',
      ),
      UnifiedEpisode(
        id: '\$animeId||ep_2',
        number: 2,
        title: 'Episode 2: Demo Continuation',
        thumbnailUrl: 'https://via.placeholder.com/640x360.png?text=Ep+2',
      ),
    ];
  }

  @override
  Future<List<VideoServer>> getServers(String episodeId) async {
    return [
      const VideoServer(
        id: '${sourceId}_sub',
        name: '$displayName Sub',
        type: ServerType.sub,
      ),
      const VideoServer(
        id: '${sourceId}_dub',
        name: '$displayName Dub',
        type: ServerType.dub,
      ),
    ];
  }

  @override
  Future<List<VideoStream>> getSources(String episodeId, VideoServer server) async {
    return [
      const VideoStream(
        url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
        quality: '1080p',
        subtitles: [],
      ),
    ];
  }
}
''';
}
