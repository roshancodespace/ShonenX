import 'dart:convert';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/data/translation/base_translation_provider.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';

class GeminiTranslationProvider implements BaseTranslationProvider {
  static final _log = AppLogger.scope('GeminiTranslationProvider');
  final HTTP _httpClient;

  GeminiTranslationProvider(this._httpClient);

  @override
  TranslationProviderType get type => TranslationProviderType.gemini;

  @override
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    required SubtitleTranslationConfig config,
  }) async {
    if (texts.isEmpty) return [];
    if (config.geminiApiKey.trim().isEmpty) {
      throw Exception('Gemini API key is missing');
    }

    final results = <String>[];
    const chunkSize = 40;

    for (int i = 0; i < texts.length; i += chunkSize) {
      final end = (i + chunkSize < texts.length) ? i + chunkSize : texts.length;
      final chunk = texts.sublist(i, end);

      final translatedChunk = await _translateChunk(
        chunk,
        targetLanguage: targetLanguage,
        config: config,
      );
      results.addAll(translatedChunk);
    }

    return results;
  }

  Future<List<String>> _translateChunk(
    List<String> chunk, {
    required String targetLanguage,
    required SubtitleTranslationConfig config,
  }) async {
    final model = config.geminiModel.isNotEmpty
        ? config.geminiModel
        : 'gemini-3.5-flash-lite';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${config.geminiApiKey.trim()}';

    final prompt =
        'You are an expert anime and media subtitle translator. '
        'Translate the following JSON array of subtitle dialogue lines into "$targetLanguage". '
        'Preserve the original dialogue tone, slang, character voice, and timing markers. '
        'Return ONLY a valid JSON array of translated strings with the exact same number of items (${chunk.length}) in identical order. '
        'Source lines:\n${jsonEncode(chunk)}';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      },
    });

    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API error ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini returned no candidates');
      }

      final content = candidates[0]['content'];
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini returned empty parts');
      }

      final text = parts[0]['text'] as String?;
      if (text == null || text.isEmpty) {
        throw Exception('Gemini returned null text');
      }

      final dynamic parsed = jsonDecode(text.trim());
      if (parsed is List) {
        final list = parsed.map((e) => e.toString()).toList();
        if (list.length == chunk.length) {
          return list;
        } else if (list.length > chunk.length) {
          return list.sublist(0, chunk.length);
        } else {
          // Pad with original lines if short
          while (list.length < chunk.length) {
            list.add(chunk[list.length]);
          }
          return list;
        }
      }

      throw Exception('Gemini did not return a JSON array');
    } catch (e) {
      _log.e('Gemini translation failed: $e');
      rethrow;
    }
  }
}
