import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';

abstract class BaseTranslationProvider {
  TranslationProviderType get type;

  /// Translates a batch of subtitle text strings.
  /// Throws an exception if translation fails so the chain can failover to the next provider.
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = 'auto',
    required SubtitleTranslationConfig config,
  });
}

