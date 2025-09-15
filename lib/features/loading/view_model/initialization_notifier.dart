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

// A unique object to represent "no error" for clarity in the state.
const noError = Object();

// 1. Define the possible states of initialization.
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

// 2. Create an immutable state class to hold all initialization data.
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

  // Initial state constructor
  factory InitializationState.initial() => const InitializationState(
        status: InitializationStatus.idle,
        message: 'Initializing...',
        progress: 0.0,
        error: noError,
      );

  // Getters for easier consumption in the UI
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

// 3. Create the StateNotifier to manage the state and logic.
class InitializationNotifier extends StateNotifier<InitializationState> {
  final Ref _ref;
  Timer? _timeoutTimer;
  static const Duration _initializationTimeout = Duration(seconds: 30);

  InitializationNotifier(this._ref) : super(InitializationState.initial());

  Future<void> initialize() async {
    // Prevent re-initialization if already running or completed
    if (state.status != InitializationStatus.idle && !state.hasError) return;

    _startTimeoutTimer();

    try {
      _updateState(
        status: InitializationStatus.initializing,
        message: 'Setting up core services...',
        progress: 0.1,
      );

      _updateState(
        status: InitializationStatus.loadingSources,
        message: 'Loading anime sources...',
        progress: 0.3,
      );
      _ref.read(animeSourceRegistryProvider).initialize();

      _updateState(
        status: InitializationStatus.authenticating,
        message: 'Logging you in',
        progress: 0.35
      );
      _ref.read(authProvider.notifier).init();

      final registryState = _ref.read(animeSourceRegistryProvider);
      if (!registryState.isInitialized) {
        throw Exception(
            'Anime source registry failed to initialize: ${registryState.error ?? 'Unknown error'}');
      }
      AppLogger.d('✅ Anime source registry initialized');

      _updateState(
          status: InitializationStatus.initializing,
          message: 'Loading extensions',
          progress: 0.4);

      final sourceState = _ref.read(sourceProvider.notifier);
      await sourceState.initialize();

      AppLogger.d('✅ Extensions loaded');

      _updateState(
        status: InitializationStatus.loadingHomepage,
        message: 'Preparing homepage...',
        progress: 0.6,
      );
      await _ref.read(homepageProvider.notifier).initialize();
      AppLogger.d('✅ Homepage initialized');

      _updateState(
        status: InitializationStatus.applyingSettings,
        message: 'Applying settings...',
        progress: 0.8,
      );
      await _applyUISettings();
      await _applyThemeSettings();
      AppLogger.d('✅ Settings applied');

      _updateState(progress: 0.95, message: 'Finalizing setup...');
      await Future.delayed(const Duration(milliseconds: 800));

      _timeoutTimer?.cancel();
      _updateState(
        status: InitializationStatus.success,
        message: 'Ready!',
        progress: 1.0,
      );
      AppLogger.d('✅ App initialization successful');
    } catch (e, stack) {
      _timeoutTimer?.cancel();
      AppLogger.e('Critical initialization error', e, stack);
      _updateState(
        status: InitializationStatus.error,
        message: 'Error occurred',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void retry() {
    // Reset state and re-initialize
    state = InitializationState.initial();
    initialize();
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_initializationTimeout, () {
      if (state.status != InitializationStatus.success) {
        AppLogger.e('Initialization timeout');
        _updateState(
          status: InitializationStatus.error,
          message: 'Error occurred',
          error:
              'Initialization timed out. Please check your network connection and restart the app.',
        );
      }
    });
  }

  Future<void> _applyUISettings() async {
    try {
      final uiSettings = _ref.read(uiSettingsProvider);
      if (uiSettings.immersiveMode) {
        await UIHelper.enableImmersiveMode();
      }
    } catch (e) {
      AppLogger.w('Failed to apply UI settings: $e');
    }
  }

  Future<void> _applyThemeSettings() async {
    try {
      _ref.read(themeSettingsProvider);
    } catch (e) {
      AppLogger.w('Failed to apply Theme settings: $e');
    }
  }

  void _updateState({
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
        'Init State: ${state.message} (${(state.progress * 100).toInt()}%)');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }
}

// 4. Create the final provider that the UI will interact with.
final initializationProvider =
    StateNotifierProvider<InitializationNotifier, InitializationState>(
  (ref) => InitializationNotifier(ref),
);
