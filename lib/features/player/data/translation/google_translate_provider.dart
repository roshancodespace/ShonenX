import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/data/translation/base_translation_provider.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';

class GoogleTranslateProvider implements BaseTranslationProvider {
  static final _log = AppLogger.scope('GoogleTranslateProvider');
  final HTTP _httpClient;

  GoogleTranslateProvider(this._httpClient);

  @override
  TranslationProviderType get type => TranslationProviderType.google;

  @override
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    required SubtitleTranslationConfig config,
  }) async {
    if (texts.isEmpty) return [];

    // Clean target language code e.g. 'eng' -> 'en', 'spa' -> 'es'
    final tl = _mapToGoogleLang(targetLanguage);
    final results = <String>[];

    // Batch in chunks of 20 to ensure reliability with public web RPC
    const chunkSize = 20;
    for (int i = 0; i < texts.length; i += chunkSize) {
      final end = (i + chunkSize < texts.length) ? i + chunkSize : texts.length;
      final chunk = texts.sublist(i, end);

      final translatedChunk = await _translateChunk(
        chunk,
        targetLanguage: tl,
        sourceLanguage: sourceLanguage,
      );
      results.addAll(translatedChunk);
    }

    return results;
  }

  Future<List<String>> _translateChunk(
    List<String> chunk, {
    required String targetLanguage,
    required String sourceLanguage,
  }) async {
    const delimiter = ' \n[[---§---]]\n ';
    final combinedText = chunk.join(delimiter);

    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sourceLanguage&tl=$targetLanguage&dt=t',
    );

    try {
      final response = await _httpClient.post(
        uri.toString(),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        body: 'q=${Uri.encodeQueryComponent(combinedText)}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Google Translate error: HTTP ${response.statusCode} - ${response.body}',
        );
      }

      final dynamic data = jsonDecode(response.body);
      if (data is! List || data.isEmpty || data[0] is! List) {
        throw Exception('Unexpected response format from Google Translate');
      }

      final sb = StringBuffer();
      for (final segment in data[0] as List) {
        if (segment is List && segment.isNotEmpty && segment[0] != null) {
          sb.write(segment[0].toString());
        }
      }

      final translatedCombined = sb.toString();
      final parts = translatedCombined.split(RegExp(r'\s*\[\[---§---\]\]\s*'));

      if (parts.length == chunk.length) {
        return parts.map((p) => p.trim()).toList();
      } else {
        // Fallback: translate individually if delimiter was corrupted
        _log.w(
          'Delimiter mismatch (${parts.length} vs ${chunk.length}), translating individually',
        );
        return _translateIndividually(
          chunk,
          targetLanguage: targetLanguage,
          sourceLanguage: sourceLanguage,
        );
      }
    } catch (e) {
      _log.e('Google translate chunk failed: $e');
      rethrow;
    }
  }

  Future<List<String>> _translateIndividually(
    List<String> chunk, {
    required String targetLanguage,
    required String sourceLanguage,
  }) async {
    final list = <String>[];
    for (final text in chunk) {
      if (text.trim().isEmpty) {
        list.add(text);
        continue;
      }
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sourceLanguage&tl=$targetLanguage&dt=t&q=${Uri.encodeQueryComponent(text)}',
      );
      final response = await _httpClient.get(uri.toString());
      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        final sb = StringBuffer();
        if (data is List && data.isNotEmpty && data[0] is List) {
          for (final segment in data[0] as List) {
            if (segment is List && segment.isNotEmpty && segment[0] != null) {
              sb.write(segment[0].toString());
            }
          }
        }
        list.add(sb.toString().trim());
      } else {
        list.add(text);
      }
    }
    return list;
  }

  String _mapToGoogleLang(String lang) {
    final lower = lang.toLowerCase().trim();
    if (lower.length == 2) return lower;
    const map = {
      'eng': 'en',
      'spa': 'es',
      'fre': 'fr',
      'ger': 'de',
      'por': 'pt',
      'ita': 'it',
      'rus': 'ru',
      'ara': 'ar',
      'hin': 'hi',
      'ind': 'id',
      'tur': 'tr',
      'vie': 'vi',
      'tha': 'th',
      'pol': 'pl',
      'chi': 'zh-CN',
      'zho': 'zh-CN',
      'kor': 'ko',
      'jpn': 'ja',
      'dut': 'nl',
      'tgl': 'tl',
      'fil': 'tl',
      'may': 'ms',
      'msa': 'ms',
      'swe': 'sv',
      'ukr': 'uk',
      'rum': 'ro',
      'ron': 'ro',
      'gre': 'el',
      'ell': 'el',
      'hun': 'hu',
      'cze': 'cs',
      'ces': 'cs',
      'dan': 'da',
      'fin': 'fi',
      'nor': 'no',
      'heb': 'iw',
    };
    return map[lower] ?? lower;
  }
}

