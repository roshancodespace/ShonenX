import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/data/translation/base_translation_provider.dart';
import 'package:shonenx/features/player/data/translation/deepl_translation_provider.dart';
import 'package:shonenx/features/player/data/translation/gemini_translation_provider.dart';
import 'package:shonenx/features/player/data/translation/google_translate_provider.dart';
import 'package:shonenx/features/player/data/translation/openai_compatible_provider.dart';
import 'package:shonenx/features/player/data/translation/subtitle_cache_service.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';

class TranslationChainService {
  static final _log = AppLogger.scope('TranslationChainService');
  final HTTP _httpClient;

  late final Map<TranslationProviderType, BaseTranslationProvider> _providers;

  TranslationChainService(this._httpClient) {
    _providers = {
      TranslationProviderType.google: GoogleTranslateProvider(_httpClient),
      TranslationProviderType.gemini: GeminiTranslationProvider(_httpClient),
      TranslationProviderType.deepl: DeepLTranslationProvider(_httpClient),
      TranslationProviderType.openai: OpenAICompatibleProvider(_httpClient),
    };
  }

  /// Translates a full list of subtitle cues through the prioritized provider chain,
  /// with automatic fallback on failure and persistent disk caching.
  Future<List<SubtitleCue>> translateCues({
    required List<SubtitleCue> cues,
    required String targetLanguage,
    required SubtitleTranslationConfig config,
    String? sourceUrl,
    void Function(double progress, String providerName)? onProgress,
  }) async {
    if (cues.isEmpty) return [];

    // 1. Check disk cache if sourceUrl is available
    final cacheKey = sourceUrl != null
        ? SubtitleCacheService.generateKey(
            sourceUrl: sourceUrl,
            targetLang: targetLanguage,
            count: cues.length,
          )
        : null;

    if (cacheKey != null) {
      final cached = await SubtitleCacheService.getCachedCues(cacheKey);
      if (cached != null && cached.length == cues.length) {
        _log.i('Using cached subtitle translation ($targetLanguage)');
        return cached;
      }
    }

    // 2. Extract texts to translate
    final originalTexts = cues.map((c) => c.text).toList();

    // 3. Resolve active provider candidates based on user priority and config
    final candidateTypes = <TranslationProviderType>[];
    for (final type in config.providerPriority) {
      final isEnabled = config.providerEnabled[type] ?? false;
      if (!isEnabled) continue;

      if (type == TranslationProviderType.gemini &&
          config.geminiApiKey.trim().isEmpty) {
        continue;
      }
      if (type == TranslationProviderType.deepl &&
          config.deeplApiKey.trim().isEmpty) {
        continue;
      }
      if (type == TranslationProviderType.openai &&
          config.openaiApiKey.trim().isEmpty) {
        continue;
      }
      candidateTypes.add(type);
    }

    // Always ensure Google Translate is available as an ultimate fallback if all else fail
    if (!candidateTypes.contains(TranslationProviderType.google)) {
      candidateTypes.add(TranslationProviderType.google);
    }

    _log.i(
      'Starting translation to "$targetLanguage" with candidate chain: '
      '${candidateTypes.map((t) => t.name).join(' -> ')}',
    );

    // 4. Try providers in priority sequence with failover
    List<String>? translatedTexts;
    String? successfulProviderName;

    for (final type in candidateTypes) {
      final provider = _providers[type];
      if (provider == null) continue;

      try {
        _log.i('Attempting translation with provider: ${type.displayName}');
        onProgress?.call(0.2, type.displayName);

        translatedTexts = await provider.translateBatch(
          texts: originalTexts,
          targetLanguage: targetLanguage,
          config: config,
        );

        if (translatedTexts.isNotEmpty) {
          successfulProviderName = type.displayName;
          _log.i('Translation succeeded via ${type.displayName}');
          break;
        }
      } catch (e, st) {
        _log.w(
          'Provider ${type.displayName} failed ($e). Falling back to next in chain...',
          e,
          st,
        );
      }
    }

    if (translatedTexts == null || translatedTexts.isEmpty) {
      throw Exception('All translation providers in the priority chain failed.');
    }

    // 5. Recombine translated texts with original timing cues
    final translatedCues = <SubtitleCue>[];
    for (int i = 0; i < cues.length; i++) {
      final text = i < translatedTexts.length
          ? translatedTexts[i]
          : cues[i].text;
      translatedCues.add(
        SubtitleCue(
          start: cues[i].start,
          end: cues[i].end,
          text: text,
          alignment: cues[i].alignment,
        ),
      );
    }

    // 6. Save to disk cache for instantaneous future loads
    if (cacheKey != null) {
      await SubtitleCacheService.saveCachedCues(cacheKey, translatedCues);
    }

    onProgress?.call(1.0, successfulProviderName ?? 'Done');
    return translatedCues;
  }
}

