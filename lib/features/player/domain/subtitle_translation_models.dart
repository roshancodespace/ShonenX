enum TranslationProviderType {
  google,
  gemini,
  deepl,
  openai;

  String get displayName {
    switch (this) {
      case TranslationProviderType.google:
        return 'Google Translate (Free)';
      case TranslationProviderType.gemini:
        return 'Google Gemini API';
      case TranslationProviderType.deepl:
        return 'DeepL API';
      case TranslationProviderType.openai:
        return 'OpenAI / Custom LLM';
    }
  }

  String get description {
    switch (this) {
      case TranslationProviderType.google:
        return 'Free public service, no API key required';
      case TranslationProviderType.gemini:
        return 'Fast and context-aware with your Gemini API key';
      case TranslationProviderType.deepl:
        return 'High accuracy translation with DeepL Free or Pro key';
      case TranslationProviderType.openai:
        return 'Compatible with OpenAI, Groq, Ollama, DeepSeek, etc.';
    }
  }

  bool get requiresApiKey {
    switch (this) {
      case TranslationProviderType.google:
        return false;
      case TranslationProviderType.gemini:
      case TranslationProviderType.deepl:
      case TranslationProviderType.openai:
        return true;
    }
  }
}

enum TranslationStrategy {
  bulk,
  onDemand;

  String get displayName {
    switch (this) {
      case TranslationStrategy.bulk:
        return 'Bulk Batch (Pre-translate with Cache)';
      case TranslationStrategy.onDemand:
        return 'On-Demand (Rolling Window)';
    }
  }

  String get description {
    switch (this) {
      case TranslationStrategy.bulk:
        return 'Translates all subtitle lines ahead of time and caches them on disk for instant seeking.';
      case TranslationStrategy.onDemand:
        return 'Translates upcoming dialogue lines 60-90s ahead as you watch to minimize upfront requests.';
    }
  }
}

class SubtitleTranslationConfig {
  final bool enabled;
  final bool autoTranslateIfPreferredMissing;
  final String defaultTargetLanguage;
  final TranslationStrategy strategy;
  final List<TranslationProviderType> providerPriority;
  final Map<TranslationProviderType, bool> providerEnabled;
  final String geminiApiKey;
  final String geminiModel;
  final String deeplApiKey;
  final bool deeplUsePro;
  final String openaiApiKey;
  final String openaiBaseUrl;
  final String openaiModel;

  const SubtitleTranslationConfig({
    this.enabled = false,
    this.autoTranslateIfPreferredMissing = false,
    this.defaultTargetLanguage = 'es',
    this.strategy = TranslationStrategy.bulk,
    this.providerPriority = const [
      TranslationProviderType.google,
      TranslationProviderType.gemini,
      TranslationProviderType.deepl,
      TranslationProviderType.openai,
    ],
    this.providerEnabled = const {
      TranslationProviderType.google: true,
      TranslationProviderType.gemini: false,
      TranslationProviderType.deepl: false,
      TranslationProviderType.openai: false,
    },
    this.geminiApiKey = '',
    this.geminiModel = 'gemini-3.5-flash-lite',
    this.deeplApiKey = '',
    this.deeplUsePro = false,
    this.openaiApiKey = '',
    this.openaiBaseUrl = 'https://api.openai.com/v1',
    this.openaiModel = 'gpt-4o-mini',
  });

  SubtitleTranslationConfig copyWith({
    bool? enabled,
    bool? autoTranslateIfPreferredMissing,
    String? defaultTargetLanguage,
    TranslationStrategy? strategy,
    List<TranslationProviderType>? providerPriority,
    Map<TranslationProviderType, bool>? providerEnabled,
    String? geminiApiKey,
    String? geminiModel,
    String? deeplApiKey,
    bool? deeplUsePro,
    String? openaiApiKey,
    String? openaiBaseUrl,
    String? openaiModel,
  }) {
    return SubtitleTranslationConfig(
      enabled: enabled ?? this.enabled,
      autoTranslateIfPreferredMissing:
          autoTranslateIfPreferredMissing ??
          this.autoTranslateIfPreferredMissing,
      defaultTargetLanguage:
          defaultTargetLanguage ?? this.defaultTargetLanguage,
      strategy: strategy ?? this.strategy,
      providerPriority: providerPriority ?? this.providerPriority,
      providerEnabled: providerEnabled ?? this.providerEnabled,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiModel: geminiModel ?? this.geminiModel,
      deeplApiKey: deeplApiKey ?? this.deeplApiKey,
      deeplUsePro: deeplUsePro ?? this.deeplUsePro,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      openaiBaseUrl: openaiBaseUrl ?? this.openaiBaseUrl,
      openaiModel: openaiModel ?? this.openaiModel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'autoTranslateIfPreferredMissing': autoTranslateIfPreferredMissing,
      'defaultTargetLanguage': defaultTargetLanguage,
      'strategy': strategy.name,
      'providerPriority': providerPriority.map((p) => p.name).toList(),
      'providerEnabled': providerEnabled.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'geminiApiKey': geminiApiKey,
      'geminiModel': geminiModel,
      'deeplApiKey': deeplApiKey,
      'deeplUsePro': deeplUsePro,
      'openaiApiKey': openaiApiKey,
      'openaiBaseUrl': openaiBaseUrl,
      'openaiModel': openaiModel,
    };
  }

  factory SubtitleTranslationConfig.fromMap(Map<String, dynamic> map) {
    List<TranslationProviderType> priority = [
      TranslationProviderType.google,
      TranslationProviderType.gemini,
      TranslationProviderType.deepl,
      TranslationProviderType.openai,
    ];

    if (map['providerPriority'] is List) {
      final list = (map['providerPriority'] as List)
          .map(
            (e) => TranslationProviderType.values
                .where((p) => p.name == e)
                .firstOrNull,
          )
          .whereType<TranslationProviderType>()
          .toList();
      if (list.isNotEmpty) {
        for (final p in TranslationProviderType.values) {
          if (!list.contains(p)) list.add(p);
        }
        priority = list;
      }
    }

    final enabledMap = <TranslationProviderType, bool>{
      TranslationProviderType.google: true,
      TranslationProviderType.gemini: false,
      TranslationProviderType.deepl: false,
      TranslationProviderType.openai: false,
    };

    if (map['providerEnabled'] is Map) {
      final m = map['providerEnabled'] as Map;
      for (final p in TranslationProviderType.values) {
        if (m.containsKey(p.name) && m[p.name] is bool) {
          enabledMap[p] = m[p.name] as bool;
        }
      }
    }

    TranslationStrategy strat = TranslationStrategy.bulk;
    if (map['strategy'] == 'onDemand') {
      strat = TranslationStrategy.onDemand;
    }

    return SubtitleTranslationConfig(
      enabled: map['enabled'] ?? false,
      autoTranslateIfPreferredMissing:
          map['autoTranslateIfPreferredMissing'] ?? false,
      defaultTargetLanguage: map['defaultTargetLanguage'] ?? 'es',
      strategy: strat,
      providerPriority: priority,
      providerEnabled: enabledMap,
      geminiApiKey: map['geminiApiKey'] ?? '',
      geminiModel: map['geminiModel'] ?? 'gemini-2.5-flash',
      deeplApiKey: map['deeplApiKey'] ?? '',
      deeplUsePro: map['deeplUsePro'] ?? false,
      openaiApiKey: map['openaiApiKey'] ?? '',
      openaiBaseUrl: map['openaiBaseUrl'] ?? 'https://api.openai.com/v1',
      openaiModel: map['openaiModel'] ?? 'gpt-4o-mini',
    );
  }
}

/// Comprehensive ISO language map for subtitle selection and translation.
const Map<String, String> kSupportedSubtitleLanguages = {
  'en': 'English',
  'es': 'Spanish (Español)',
  'fr': 'French (Français)',
  'de': 'German (Deutsch)',
  'pt': 'Portuguese (Português)',
  'it': 'Italian (Italiano)',
  'ru': 'Russian (Русский)',
  'ar': 'Arabic (العربية)',
  'hi': 'Hindi (हिन्दी)',
  'id': 'Indonesian (Bahasa Indonesia)',
  'tr': 'Turkish (Türkçe)',
  'vi': 'Vietnamese (Tiếng Việt)',
  'th': 'Thai (ไทย)',
  'pl': 'Polish (Polski)',
  'zh': 'Chinese (中文)',
  'yue': 'Cantonese (粵語)',
  'ko': 'Korean (한국어)',
  'ja': 'Japanese (日本語)',
  'nl': 'Dutch (Nederlands)',
  'fil': 'Filipino (Tagalog)',
  'ms': 'Malay (Bahasa Melayu)',
  'sv': 'Swedish (Svenska)',
  'uk': 'Ukrainian (Українська)',
  'ro': 'Romanian (Română)',
  'el': 'Greek (Ελληνικά)',
  'hu': 'Hungarian (Magyar)',
  'cs': 'Czech (Čeština)',
  'da': 'Danish (Dansk)',
  'fi': 'Finnish (Suomi)',
  'no': 'Norwegian (Norsk)',
  'he': 'Hebrew (עברית)',
  'bn': 'Bengali (বাংলা)',
  'ta': 'Tamil (தமிழ்)',
  'te': 'Telugu (తెలుగు)',
  'fa': 'Persian (فارسی)',
  'ur': 'Urdu (اردو)',
};
