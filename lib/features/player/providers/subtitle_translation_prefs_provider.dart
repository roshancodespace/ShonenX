import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class SubtitleTranslationPrefsNotifier
    extends Notifier<SubtitleTranslationConfig> {
  static const _key = 'subtitle_translation_config';
  Timer? _debounce;

  @override
  SubtitleTranslationConfig build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        return SubtitleTranslationConfig.fromMap(jsonDecode(jsonStr));
      } catch (_) {}
    }
    return const SubtitleTranslationConfig();
  }

  void updateConfig(SubtitleTranslationConfig newConfig) {
    state = newConfig;
    _saveDb();
  }

  void toggleEnabled(bool value) {
    state = state.copyWith(enabled: value);
    _saveDb();
  }

  void setEnabled(bool value) => toggleEnabled(value);

  void setAutoTranslateIfPreferredMissing(bool value) {
    state = state.copyWith(autoTranslateIfPreferredMissing: value);
    _saveDb();
  }

  void setDefaultTargetLanguage(String lang) {
    state = state.copyWith(defaultTargetLanguage: lang);
    _saveDb();
  }

  void setStrategy(TranslationStrategy strategy) {
    state = state.copyWith(strategy: strategy);
    _saveDb();
  }

  void toggleProvider(TranslationProviderType type, bool enabled) {
    final updated = Map<TranslationProviderType, bool>.from(
      state.providerEnabled,
    );
    updated[type] = enabled;
    state = state.copyWith(providerEnabled: updated);
    _saveDb();
  }

  void setProviderEnabled(TranslationProviderType type, bool enabled) =>
      toggleProvider(type, enabled);

  void reorderProviders(int oldIndex, int newIndex) {
    final list = List<TranslationProviderType>.from(state.providerPriority);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(providerPriority: list);
    _saveDb();
  }

  void setGeminiApiKey(String key) {
    state = state.copyWith(geminiApiKey: key);
    _saveDb();
  }

  void setGeminiModel(String model) {
    state = state.copyWith(geminiModel: model);
    _saveDb();
  }

  void setDeeplApiKey(String key) {
    state = state.copyWith(deeplApiKey: key);
    _saveDb();
  }

  void setDeeplUsePro(bool usePro) {
    state = state.copyWith(deeplUsePro: usePro);
    _saveDb();
  }

  void setOpenaiApiKey(String key) {
    state = state.copyWith(openaiApiKey: key);
    _saveDb();
  }

  void setOpenaiBaseUrl(String url) {
    state = state.copyWith(openaiBaseUrl: url);
    _saveDb();
  }

  void setOpenaiModel(String model) {
    state = state.copyWith(openaiModel: model);
    _saveDb();
  }

  void _saveDb() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final prefs = ref.read(sharedPreferencesProvider);
      final newValue = jsonEncode(state.toMap());
      if (prefs.getString(_key) != newValue) {
        prefs.setString(_key, newValue);
      }
    });
  }
}

final subtitleTranslationPrefsProvider = NotifierProvider<
  SubtitleTranslationPrefsNotifier,
  SubtitleTranslationConfig
>(SubtitleTranslationPrefsNotifier.new);
