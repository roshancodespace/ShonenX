import 'dart:async';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    hide isar;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/permissions.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/home/view_model/homepage_notifier.dart';
import 'package:shonenx/core/providers/settings/source_notifier.dart';
import 'package:shonenx/core/providers/settings/theme_notifier.dart';
import 'package:shonenx/core/providers/settings/ui_notifier.dart';
import 'package:shonenx/helpers/ui.dart';
import 'package:shonenx/main.dart';
import 'package:shonenx/storage_provider.dart';

part 'initialization_notifier.g.dart';

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
  );

  bool get hasError => error != null;
  bool get isCompleted => status == InitializationStatus.success;

  InitializationState copyWith({
    InitializationStatus? status,
    String? message,
    double? progress,
    Object? error,
    StackTrace? stackTrace,
    bool clearError = false,
  }) {
    return InitializationState(
      status: status ?? this.status,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      stackTrace: clearError ? null : (stackTrace ?? this.stackTrace),
    );
  }
}

@Riverpod(keepAlive: true)
class Initialization extends _$Initialization {
  Timer? _timeoutTimer;
  static const _timeout = Duration(seconds: 30);

  @override
  InitializationState build() {
    ref.onDispose(() => _timeoutTimer?.cancel());
    return InitializationState.initial();
  }

  Future<void> initialize() async {
    if (_isAlreadyRunning) {
      AppLogger.v('Initialization already running — skipped');
      return;
    }

    AppLogger.section('APP INITIALIZATION');
    _startTimeout();

    try {
      await _initializeCore();
      await _initializeExtensions();
      await _initializeSources();
      await _authenticate();
      await _initializeHomepage();
      await _applySettings();
      await UniversalHttpClient.instance.cleanUp();
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

    final registry = ref.read(animeSourceRegistryProvider);

    AppLogger.infoPair('Registry initialized', registry.isInitialized);

    if (!registry.isInitialized) {
      AppLogger.fail('Anime source registry failed');
      throw StateError(registry.error?.toString() ?? 'Unknown registry error');
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

    await ref.read(sourceProvider.notifier).initialize();

    AppLogger.success('Extensions loaded');
  }

  Future<void> _authenticate() async {
    AppLogger.section('AUTHENTICATION');

    _emit(
      status: InitializationStatus.authenticating,
      message: 'Authenticating…',
      progress: 0.45,
    );

    // Initializing the auth provider
    ref.read(authProvider.notifier);

    AppLogger.success('Auth bootstrap complete');
  }

  Future<void> _initializeHomepage() async {
    AppLogger.section('HOMEPAGE');

    _emit(
      status: InitializationStatus.loadingHomepage,
      message: 'Preparing homepage…',
      progress: 0.65,
    );

    await ref.read(homepageProvider.notifier).initialize();

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

  Future<void> _initializeExtensions() async {
    AppLogger.section('EXTENSIONS');

    _emit(
      status: InitializationStatus.loadingSources,
      message: 'Loading extensions…',
      progress: 0.35,
    );

    if (!Permissions.storage) {
      if (!await Permissions.requestStoragePermission()) {
        AppLogger.fail("Storage permission denied");
        throw StateError("Failed to get storage access");
      }
    }

    isar = await StorageProvider.initDB(null, inspector: kDebugMode);
    final bridge = DartotsuExtensionBridge();
    await bridge.init(isar, 'ShonenX');

    AppLogger.success('Extensions loaded');
  }

  // ---------------------------------------------------------------------------
  // Settings helpers (non-fatal)
  // ---------------------------------------------------------------------------

  Future<void> _applyUISettings() async {
    try {
      final ui = ref.read(uiSettingsProvider);
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
      ref.read(themeSettingsProvider);
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
}
