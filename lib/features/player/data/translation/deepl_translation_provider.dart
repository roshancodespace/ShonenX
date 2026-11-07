import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/data/translation/base_translation_provider.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';

class DeepLTranslationProvider implements BaseTranslationProvider {
  static final _log = AppLogger.scope('DeepLTranslationProvider');
  final HTTP _httpClient;

  DeepLTranslationProvider(this._httpClient);

  @override
  TranslationProviderType get type => TranslationProviderType.deepl;

  @override
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    required SubtitleTranslationConfig config,
  }) async {
    if (texts.isEmpty) return [];
    if (config.deeplApiKey.trim().isEmpty) {
      throw Exception('DeepL API key is missing');
    }

    final key = config.deeplApiKey.trim();
    final isFreeKey = key.endsWith(':fx') || !config.deeplUsePro;
    final host = isFreeKey ? 'api-free.deepl.com' : 'api.deepl.com';
    final url = 'https://$host/v2/translate';

    final targetLang = _mapToDeepLLang(targetLanguage);
    final results = <String>[];
    const chunkSize = 50;

    for (int i = 0; i < texts.length; i += chunkSize) {
      final end = (i + chunkSize < texts.length) ? i + chunkSize : texts.length;
      final chunk = texts.sublist(i, end);

      final body = jsonEncode({'text': chunk, 'target_lang': targetLang});

      try {
        final response = await _httpClient.post(
          url,
          headers: {
            'Authorization': 'DeepL-Auth-Key $key',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode != 200) {
          throw Exception(
            'DeepL API error ${response.statusCode}: ${response.body}',
          );
        }

        final dynamic data = jsonDecode(response.body);
        final translations = data['translations'] as List?;
        if (translations == null) {
          throw Exception('DeepL returned null translations list');
        }

        final chunkResults = translations
            .map((item) => (item['text'] ?? '').toString())
            .toList();
        results.addAll(chunkResults);
      } catch (e) {
        _log.e('DeepL batch translation error: $e');
        rethrow;
      }
    }

    return results;
  }

  String _mapToDeepLLang(String lang) {
    final lower = lang.toLowerCase().trim();
    switch (lower) {
      case 'en':
      case 'eng':
        return 'EN-US';
      case 'pt':
      case 'por':
        return 'PT-BR';
      case 'zh':
      case 'chi':
      case 'zho':
        return 'ZH-HANS';
      default:
        if (lower.length > 2) {
          return lower.substring(0, 2).toUpperCase();
        }
        return lower.toUpperCase();
    }
  }
}
