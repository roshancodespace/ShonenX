import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/security_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/providers/security_prefs_provider.dart';

class AppLockState {
  final bool isLocked;
  final DateTime? lastPausedAt;

  const AppLockState({required this.isLocked, this.lastPausedAt});

  AppLockState copyWith({
    bool? isLocked,
    DateTime? lastPausedAt,
    bool clearPausedAt = false,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      lastPausedAt: clearPausedAt ? null : (lastPausedAt ?? this.lastPausedAt),
    );
  }
}

class AppLockNotifier extends Notifier<AppLockState> {
  static final _log = AppLogger.scope('AppLockNotifier');
  DateTime? _lastUnlockedAt;

  @override
  AppLockState build() {
    final prefs = ref.watch(securityPrefsProvider);
    final shouldLockOnStart = prefs.isAppLockEnabled;
    return AppLockState(isLocked: shouldLockOnStart);
  }

  void unlock() {
    _log.i('App unlocked');
    _lastUnlockedAt = DateTime.now();
    state = state.copyWith(isLocked: false, clearPausedAt: true);
  }

  void lock() {
    _log.i('App manually locked');
    state = state.copyWith(isLocked: true, clearPausedAt: true);
  }

  void recordPaused() {
    final prefs = ref.read(securityPrefsProvider);
    if (!prefs.isAppLockEnabled || state.isLocked) return;

    final securityService = ref.read(securityServiceProvider);
    if (securityService.isAuthenticating) {
      _log.d('Ignoring pause event during active biometric authentication');
      return;
    }

    state = state.copyWith(lastPausedAt: DateTime.now());
  }

  void checkAndLockOnResume() {
    final prefs = ref.read(securityPrefsProvider);
    if (!prefs.isAppLockEnabled || state.isLocked) return;

    final securityService = ref.read(securityServiceProvider);
    if (securityService.isAuthenticating) {
      _log.d('Ignoring resume event during active biometric authentication');
      return;
    }

    final now = DateTime.now();
    if (_lastUnlockedAt != null &&
        now.difference(_lastUnlockedAt!) < const Duration(seconds: 2)) {
      _log.d('Ignoring resume event within unlock grace period');
      return;
    }

    final lastAuth = securityService.lastAuthSuccessAt;
    if (lastAuth != null &&
        now.difference(lastAuth) < const Duration(seconds: 2)) {
      _log.d('Ignoring resume event within biometric completion grace period');
      return;
    }

    final timeout = prefs.lockTimeout;
    if (timeout == LockTimeout.onAppRestart) return;

    final lastPaused = state.lastPausedAt;
    if (lastPaused == null) {
      return;
    }

    final duration = timeout.duration;
    if (duration != null) {
      final elapsed = now.difference(lastPaused);
      if (elapsed >= duration) {
        _log.i(
          'Auto-locking app after ${elapsed.inSeconds}s (threshold: ${duration.inSeconds}s)',
        );
        lock();
      } else {
        state = state.copyWith(clearPausedAt: true);
      }
    }
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  () => AppLockNotifier(),
);
