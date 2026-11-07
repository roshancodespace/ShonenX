import 'package:flutter_test/flutter_test.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/player/data/translation/subtitle_cache_service.dart';
import 'package:shonenx/features/player/data/translation/translation_chain_service.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';
import 'package:shonenx/features/player/providers/selection_resolver.dart';

class MockHttp implements HTTP {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('SubtitleTranslationConfig Tests', () {
    test('Default configuration should have expected defaults', () {
      const config = SubtitleTranslationConfig();
      expect(config.enabled, false);
      expect(config.autoTranslateIfPreferredMissing, false);
      expect(config.defaultTargetLanguage, 'es');
      expect(config.strategy, TranslationStrategy.bulk);
      expect(config.providerPriority.first, TranslationProviderType.google);
      expect(config.providerEnabled[TranslationProviderType.google], true);
      expect(config.providerEnabled[TranslationProviderType.gemini], false);
    });

    test('toMap and fromMap should round-trip accurately', () {
      const original = SubtitleTranslationConfig(
        enabled: true,
        autoTranslateIfPreferredMissing: true,
        defaultTargetLanguage: 'fr',
        strategy: TranslationStrategy.onDemand,
        geminiApiKey: 'test-gemini-key',
        geminiModel: 'gemini-2.5-flash',
        deeplApiKey: 'test-deepl-key',
        deeplUsePro: true,
        openaiApiKey: 'test-openai-key',
        openaiBaseUrl: 'https://api.groq.com/openai/v1',
        openaiModel: 'llama-3.3-70b-versatile',
        providerPriority: [
          TranslationProviderType.gemini,
          TranslationProviderType.openai,
          TranslationProviderType.deepl,
          TranslationProviderType.google,
        ],
        providerEnabled: {
          TranslationProviderType.gemini: true,
          TranslationProviderType.openai: true,
          TranslationProviderType.deepl: false,
          TranslationProviderType.google: true,
        },
      );

      final map = original.toMap();
      final restored = SubtitleTranslationConfig.fromMap(map);

      expect(restored.enabled, true);
      expect(restored.autoTranslateIfPreferredMissing, true);
      expect(restored.defaultTargetLanguage, 'fr');
      expect(restored.strategy, TranslationStrategy.onDemand);
      expect(restored.geminiApiKey, 'test-gemini-key');
      expect(restored.geminiModel, 'gemini-2.5-flash');
      expect(restored.deeplApiKey, 'test-deepl-key');
      expect(restored.deeplUsePro, true);
      expect(restored.openaiApiKey, 'test-openai-key');
      expect(restored.openaiBaseUrl, 'https://api.groq.com/openai/v1');
      expect(restored.openaiModel, 'llama-3.3-70b-versatile');
      expect(restored.providerPriority, [
        TranslationProviderType.gemini,
        TranslationProviderType.openai,
        TranslationProviderType.deepl,
        TranslationProviderType.google,
      ]);
      expect(restored.providerEnabled[TranslationProviderType.gemini], true);
      expect(restored.providerEnabled[TranslationProviderType.openai], true);
      expect(restored.providerEnabled[TranslationProviderType.deepl], false);
      expect(restored.providerEnabled[TranslationProviderType.google], true);
    });
  });

  group('SubtitleCacheService Key Generation', () {
    test('generateKey creates distinct and deterministic hashes', () {
      final key1 = SubtitleCacheService.generateKey(
        sourceUrl: 'https://example.com/subs.vtt',
        targetLang: 'es',
        count: 100,
      );
      final key2 = SubtitleCacheService.generateKey(
        sourceUrl: 'https://example.com/subs.vtt',
        targetLang: 'es',
        count: 100,
      );
      final key3 = SubtitleCacheService.generateKey(
        sourceUrl: 'https://example.com/subs.vtt',
        targetLang: 'fr',
        count: 100,
      );

      expect(key1, key2);
      expect(key1, isNot(equals(key3)));
      expect(key1.length, 32); // MD5 hex length
    });
  });

  group('SelectionResolver Language Matching', () {
    final resolver = SelectionResolver();

    test('matches traditional languages and their aliases', () {
      expect(resolver.matchesLanguage('English [CC]', 'en'), true);
      expect(resolver.matchesLanguage('Spanish (Latin America)', 'es'), true);
      expect(resolver.matchesLanguage('Español', 'spa'), true);
      expect(resolver.matchesLanguage('Japanese', 'ja'), true);
      expect(resolver.matchesLanguage('Français', 'fre'), true);
      expect(resolver.matchesLanguage('Deutsch', 'ger'), true);
    });

    test('matches newly expanded 35+ language aliases', () {
      expect(resolver.matchesLanguage('Bengali', 'bn'), true);
      expect(resolver.matchesLanguage('Bangla', 'ben'), true);
      expect(resolver.matchesLanguage('Tamil', 'ta'), true);
      expect(resolver.matchesLanguage('Telugu', 'te'), true);
      expect(resolver.matchesLanguage('Persian', 'fa'), true);
      expect(resolver.matchesLanguage('Farsi', 'fas'), true);
      expect(resolver.matchesLanguage('Urdu', 'ur'), true);
      expect(resolver.matchesLanguage('Cantonese', 'yue'), true);
      expect(resolver.matchesLanguage('Hong Kong', 'yue'), true);
      expect(resolver.matchesLanguage('Cantonese [Traditional]', 'yue'), true);
    });
  });

  group('TranslationChainService Chain Selection', () {
    test('Translating empty cues returns immediately', () async {
      final service = TranslationChainService(MockHttp());
      final result = await service.translateCues(
        cues: [],
        targetLanguage: 'es',
        config: const SubtitleTranslationConfig(),
      );
      expect(result, isEmpty);
    });
  });
}

