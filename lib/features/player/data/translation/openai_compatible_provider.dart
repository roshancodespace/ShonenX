import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/data/translation/base_translation_provider.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';

class OpenAICompatibleProvider implements BaseTranslationProvider {
  static final _log = AppLogger.scope('OpenAICompatibleProvider');
  final HTTP _httpClient;

  OpenAICompatibleProvider(this._httpClient);

  @override
  TranslationProviderType get type => TranslationProviderType.openai;

  @override
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    required SubtitleTranslationConfig config,
  }) async {
    if (texts.isEmpty) return [];
    if (config.openaiApiKey.trim().isEmpty) {
      throw Exception('API key is missing');
    }

    var baseUrl = config.openaiBaseUrl.trim();
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    final url = '$baseUrl/chat/completions';
    final model = config.openaiModel.isNotEmpty
        ? config.openaiModel
        : 'gpt-4o-mini';

    final results = <String>[];
    const chunkSize = 35;

    for (int i = 0; i < texts.length; i += chunkSize) {
      final end = (i + chunkSize < texts.length) ? i + chunkSize : texts.length;
      final chunk = texts.sublist(i, end);

      final prompt =
          'Translate each item in the following JSON array of subtitle dialogue lines into "$targetLanguage". '
          'Maintain the exact item count (${chunk.length}) and sequence. '
          'Return a JSON object with a "translations" key containing the array of translated strings: {"translations": ["...", "..."]}. '
          'Original lines:\n${jsonEncode(chunk)}';

      final body = jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a subtitle translator. You only reply with valid JSON containing the "translations" key with translated strings.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.2,
      });

      try {
        final response = await _httpClient.post(
          url,
          headers: {
            'Authorization': 'Bearer ${config.openaiApiKey.trim()}',
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode != 200) {
          throw Exception(
            'OpenAI compatible API error ${response.statusCode}: ${response.body}',
          );
        }

        final dynamic data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          throw Exception('No choices in response');
        }

        final message = choices[0]['message'];
        final content = message?['content'] as String?;
        if (content == null || content.isEmpty) {
          throw Exception('Empty content returned');
        }

        final parsedList = _extractTranslations(content, chunk.length);
        results.addAll(parsedList);
      } catch (e) {
        _log.e('OpenAI batch translation error: $e');
        rethrow;
      }
    }

    return results;
  }

  List<String> _extractTranslations(String content, int expectedLength) {
    var raw = content.trim();
    if (raw.startsWith('```json')) {
      raw = raw.replaceFirst('```json', '').trim();
    }
    if (raw.startsWith('```')) {
      raw = raw.replaceFirst('```', '').trim();
    }
    if (raw.endsWith('```')) {
      raw = raw.substring(0, raw.length - 3).trim();
    }

    final dynamic decoded = jsonDecode(raw);
    List? list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['translations'] is List) {
      list = decoded['translations'] as List;
    }

    if (list != null) {
      final res = list.map((e) => e.toString()).toList();
      if (res.length >= expectedLength) {
        return res.sublist(0, expectedLength);
      }
      return res;
    }

    throw Exception('Could not parse translation list from LLM output');
  }
}
