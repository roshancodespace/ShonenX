import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/player/data/translation/translation_chain_service.dart';
import 'package:shonenx/features/player/providers/custom_subtitle_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/subtitle_translation_prefs_provider.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';

final translationChainServiceProvider = Provider<TranslationChainService>((
  ref,
) {
  final http = ref.watch(httpClientProvider);
  return TranslationChainService(http);
});

class RuntimeTranslationState {
  final bool isEnabled;
  final String? targetLanguage;
  final bool isTranslating;
  final double progress;
  final String? activeProviderName;
  final String? error;
  final List<SubtitleCue>? translatedCues;
  final String? currentSourceUrl;

  const RuntimeTranslationState({
    this.isEnabled = false,
    this.targetLanguage,
    this.isTranslating = false,
    this.progress = 0.0,
    this.activeProviderName,
    this.error,
    this.translatedCues,
    this.currentSourceUrl,
  });

  RuntimeTranslationState copyWith({
    bool? isEnabled,
    String? targetLanguage,
    bool? isTranslating,
    double? progress,
    String? activeProviderName,
    String? error,
    bool clearError = false,
    List<SubtitleCue>? translatedCues,
    bool clearTranslatedCues = false,
    String? currentSourceUrl,
  }) {
    return RuntimeTranslationState(
      isEnabled: isEnabled ?? this.isEnabled,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isTranslating: isTranslating ?? this.isTranslating,
      progress: progress ?? this.progress,
      activeProviderName: activeProviderName ?? this.activeProviderName,
      error: clearError ? null : (error ?? this.error),
      translatedCues: clearTranslatedCues
          ? null
          : (translatedCues ?? this.translatedCues),
      currentSourceUrl: currentSourceUrl ?? this.currentSourceUrl,
    );
  }
}

class RuntimeSubtitleTranslationNotifier
    extends Notifier<RuntimeTranslationState> {
  static final _log = AppLogger.scope('RuntimeSubtitleTranslationNotifier');

  @override
  RuntimeTranslationState build() {
    return const RuntimeTranslationState();
  }

  /// Triggers translation for the current active subtitle track into [targetLang].
  Future<void> translateCurrentSubtitles({
    required String targetLang,
  }) async {
    final playerState = ref.read(playerControllerProvider);
    final subtitleUrl = playerState.activeSubtitle?.url;

    if (subtitleUrl == null ||
        subtitleUrl.isEmpty ||
        subtitleUrl.startsWith('internal:')) {
      _log.w('Cannot translate: active subtitle URL is missing or internal');
      return;
    }

    try {
      final sourceCues = await ref.read(rawCustomSubtitleProvider.future);
      if (sourceCues.isEmpty) {
        _log.w('Cannot translate: source cues are empty');
        return;
      }

      await translateSubtitles(
        sourceCues: sourceCues,
        targetLang: targetLang,
        sourceUrl: subtitleUrl,
      );
    } catch (e) {
      _log.e('Failed to fetch raw cues for translation: $e');
      state = state.copyWith(
        isTranslating: false,
        error: e.toString(),
      );
    }
  }

  /// Triggers translation of the current subtitle cues into [targetLang].
  Future<void> translateSubtitles({
    required List<SubtitleCue> sourceCues,
    required String targetLang,
    required String sourceUrl,
  }) async {
    if (sourceCues.isEmpty) {
      _log.w('Cannot translate empty subtitle cues');
      return;
    }

    final service = ref.read(translationChainServiceProvider);
    final config = ref.read(subtitleTranslationPrefsProvider);

    state = state.copyWith(
      isEnabled: true,
      targetLanguage: targetLang,
      isTranslating: true,
      progress: 0.1,
      clearError: true,
      currentSourceUrl: sourceUrl,
    );

    try {
      final translated = await service.translateCues(
        cues: sourceCues,
        targetLanguage: targetLang,
        config: config,
        sourceUrl: sourceUrl,
        onProgress: (p, providerName) {
          state = state.copyWith(progress: p, activeProviderName: providerName);
        },
      );

      state = state.copyWith(
        isTranslating: false,
        progress: 1.0,
        translatedCues: translated,
      );
      _log.i(
        'Successfully translated ${translated.length} subtitle cues into $targetLang',
      );
    } catch (e) {
      _log.e('Failed to translate subtitles: $e');
      state = state.copyWith(isTranslating: false, error: e.toString());
    }
  }

  void disableTranslation() {
    _log.i('Disabling runtime subtitle translation');
    state = const RuntimeTranslationState();
  }

  void resetForNewStream() {
    if (state.isEnabled) {
      // Keep targetLanguage setting but clear cues for the new stream
      state = state.copyWith(
        clearTranslatedCues: true,
        isTranslating: false,
        progress: 0.0,
        clearError: true,
      );
    }
  }
}

final runtimeSubtitleTranslationProvider =
    NotifierProvider<
      RuntimeSubtitleTranslationNotifier,
      RuntimeTranslationState
    >(RuntimeSubtitleTranslationNotifier.new);
