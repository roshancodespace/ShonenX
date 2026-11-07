import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';

class SubtitleCacheService {
  static final _log = AppLogger.scope('SubtitleCacheService');
  static Directory? _cacheDir;

  static Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/subtitle_translations');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  static String generateKey({
    required String sourceUrl,
    required String targetLang,
    int? count,
  }) {
    final raw = '$sourceUrl|$targetLang|${count ?? 0}';
    return md5.convert(utf8.encode(raw)).toString();
  }

  static Future<List<SubtitleCue>?> getCachedCues(String cacheKey) async {
    try {
      final dir = await _getCacheDirectory();
      final file = File('${dir.path}/$cacheKey.json');
      if (!await file.exists()) return null;

      final jsonStr = await file.readAsString();
      final dynamic list = jsonDecode(jsonStr);
      if (list is! List) return null;

      final cues = <SubtitleCue>[];
      for (final item in list) {
        if (item is Map) {
          cues.add(
            SubtitleCue(
              start: Duration(milliseconds: item['start'] ?? 0),
              end: Duration(milliseconds: item['end'] ?? 0),
              text: item['text'] ?? '',
              alignment: _parseAlignment(item['alignment']),
            ),
          );
        }
      }
      _log.d('Loaded ${cues.length} cached translated cues for $cacheKey');
      return cues;
    } catch (e) {
      _log.w('Failed to read cached subtitle translation: $e');
      return null;
    }
  }

  static Future<void> saveCachedCues(
    String cacheKey,
    List<SubtitleCue> cues,
  ) async {
    try {
      final dir = await _getCacheDirectory();
      final file = File('${dir.path}/$cacheKey.json');

      final list = cues.map((cue) {
        return {
          'start': cue.start.inMilliseconds,
          'end': cue.end.inMilliseconds,
          'text': cue.text,
          'alignment': cue.alignment.toString(),
        };
      }).toList();

      await file.writeAsString(jsonEncode(list), flush: true);
      _log.d('Saved ${cues.length} translated cues to cache ($cacheKey)');
    } catch (e) {
      _log.w('Failed to save subtitle translation to cache: $e');
    }
  }

  static Future<void> clearAllCache() async {
    try {
      final dir = await _getCacheDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        _cacheDir = null;
      }
    } catch (e) {
      _log.e('Failed to clear subtitle cache: $e');
    }
  }

  static Future<int> getCacheSizeBytes() async {
    try {
      final dir = await _getCacheDirectory();
      if (!await dir.exists()) return 0;
      int size = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
      return size;
    } catch (_) {
      return 0;
    }
  }

  static Alignment _parseAlignment(String? raw) {
    if (raw == null) return Alignment.bottomCenter;
    if (raw.contains('topCenter')) return Alignment.topCenter;
    if (raw.contains('topLeft')) return Alignment.topLeft;
    if (raw.contains('topRight')) return Alignment.topRight;
    if (raw.contains('center')) return Alignment.center;
    if (raw.contains('bottomLeft')) return Alignment.bottomLeft;
    if (raw.contains('bottomRight')) return Alignment.bottomRight;
    return Alignment.bottomCenter;
  }
}

