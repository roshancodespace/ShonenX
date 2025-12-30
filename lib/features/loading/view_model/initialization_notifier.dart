import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/helpers/ui.dart';

const noError = Object();

enum InitializationStatus {
  idle,
  initializing,
  authenticating,
  loadingSources,
  loadingHomepage,
  applyingSettings,
  success,
  error,
}

class InitializationState {
  final InitializationStatus status;
  final String message;
  final double progress;
  final Object? error;
  final StackTrace? stackTrace;

  const InitializationState({
    required this.status,
    required this.message,
    required this.progress,
    this.error,
    this.stackTrace,
  });

  factory InitializationState.initial() => const InitializationState(
        status: InitializationStatus.idle,
        message: 'Initializing…',
        progress: 0.0,
        error: noError,
      );

  bool get hasError => error != noError;
  bool get isCompleted => status == InitializationStatus.success;

  InitializationState copyWith({
    InitializationStatus? status,
    String? message,
    double? progress,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return InitializationState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}

class InitializationNotifier extends StateNotifier<InitializationState> {
  InitializationNotifier(this._ref) : super(InitializationState.initial());

  final Ref _ref;

  Timer? _timeoutTimer;
  static const _timeout = Duration(seconds: 30);

  Future<void> initialize() async {
    if (_isAlreadyRunning) {
      AppLogger.v('Initialization already running — skipped');
      return;
    }

    AppLogger.section('APP INITIALIZATION');
    _startTimeout();

    try {
      await _initializeCore();
      await _initializeSources();
      await _authenticate();
      await _initializeHomepage();
      await _applySettings();

      _complete();
    } catch (e, st) {
      _fail(e, st);
    }
  }

  void retry() {
    AppLogger.section('INITIALIZATION RETRY');
    state = InitializationState.initial();
    initialize();
  }

  // ---------------------------------------------------------------------------
  // Pipeline steps
  // ---------------------------------------------------------------------------

  Future<void> _initializeCore() async {
    AppLogger.section('CORE SERVICES');

    _emit(
      status: InitializationStatus.initializing,
      message: 'Setting up core services…',
      progress: 0.1,
    );

    final registry = _ref.read(animeSourceRegistryProvider);

    AppLogger.infoPair('Registry initialized', registry.isInitialized);

    if (!registry.isInitialized) {
      AppLogger.fail('Anime source registry failed');
      throw StateError(
        registry.error?.toString() ?? 'Unknown registry error',
      );
    }

    AppLogger.success('Core registry ready');
  }

  Future<void> _initializeSources() async {
    AppLogger.section('EXTENSIONS');

    _emit(
      status: InitializationStatus.loadingSources,
      message: 'Loading extensions…',
      progress: 0.35,
    );

    await _ref.read(sourceProvider.notifier).initialize();

    AppLogger.success('Extensions loaded');
  }

  Future<void> _authenticate() async {
    AppLogger.section('AUTHENTICATION');

    _emit(
      status: InitializationStatus.authenticating,
      message: 'Authenticating…',
      progress: 0.45,
    );

    _ref.read(authProvider.notifier);

    AppLogger.success('Auth bootstrap complete');
  }

  Future<void> _initializeHomepage() async {
    AppLogger.section('HOMEPAGE');

    _emit(
      status: InitializationStatus.loadingHomepage,
      message: 'Preparing homepage…',
      progress: 0.65,
    );

    await _ref.read(homepageProvider.notifier).initialize();

    AppLogger.success('Homepage initialized');
  }

  Future<void> _applySettings() async {
    AppLogger.section('SETTINGS');

    _emit(
      status: InitializationStatus.applyingSettings,
      message: 'Applying settings…',
      progress: 0.85,
    );

    await _applyUISettings();
    _applyThemeSettings();

    AppLogger.success('Settings applied');
  }

  // ---------------------------------------------------------------------------
  // Settings helpers (non-fatal)
  // ---------------------------------------------------------------------------

  Future<void> _applyUISettings() async {
    try {
      final ui = _ref.read(uiSettingsProvider);
      AppLogger.infoPair('Immersive mode', ui.immersiveMode);

      if (ui.immersiveMode) {
        await UIHelper.enableImmersiveMode();
        AppLogger.success('Immersive mode enabled');
      }
    } catch (e, st) {
      AppLogger.w('UI settings failed', e, st);
    }
  }

  void _applyThemeSettings() {
    try {
      _ref.read(themeSettingsProvider);
      AppLogger.success('Theme applied');
    } catch (e, st) {
      AppLogger.w('Theme settings failed', e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // State & lifecycle helpers
  // ---------------------------------------------------------------------------

  bool get _isAlreadyRunning =>
      state.status != InitializationStatus.idle && !state.hasError;

  void _emit({
    InitializationStatus? status,
    String? message,
    double? progress,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!mounted) return;

    state = state.copyWith(
      status: status,
      message: message,
      progress: progress,
      error: error,
      stackTrace: stackTrace,
    );

    AppLogger.d(
      'State → ${state.status.name} | ${(state.progress * 100).toInt()}%',
    );
  }

  void _complete() {
    _timeoutTimer?.cancel();

    _emit(
      status: InitializationStatus.success,
      message: 'Ready!',
      progress: 1.0,
    );

    AppLogger.section('BOOT COMPLETE');
    AppLogger.success('Application is ready 🚀');
  }

  void _fail(Object error, StackTrace stackTrace) {
    _timeoutTimer?.cancel();

    AppLogger.section('BOOT FAILED');
    AppLogger.e('Critical initialization failure', error, stackTrace);

    _emit(
      status: InitializationStatus.error,
      message: 'Something went wrong',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(_timeout, () {
      if (state.status == InitializationStatus.success) return;

      AppLogger.section('BOOT TIMEOUT');
      AppLogger.fail('Initialization timed out');

      _fail(
        'Initialization timed out. Check your network and restart the app.',
        StackTrace.current,
      );
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}

final initializationProvider =
    StateNotifierProvider<InitializationNotifier, InitializationState>(
  (ref) => InitializationNotifier(ref),
);
