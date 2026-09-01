import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/network/secure_storage.dart';
import 'package:shonenx/features/security/domain/security_prefs.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

final securityPrefsProvider =
    NotifierProvider<SecurityPrefsNotifier, SecurityPrefs>(
      SecurityPrefsNotifier.new,
    );

class SecurityPrefsNotifier extends Notifier<SecurityPrefs> {
  static const _key = 'security_prefs';
  static const _pinKey = 'shonenx_app_pin_hash';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  FlutterSecureStorage get _secureStorage => ref.read(secureStorageProvider);

  @override
  SecurityPrefs build() {
    final jsonStr = _prefs.getString(_key);
    if (jsonStr != null) {
      try {
        return SecurityPrefs.fromJson(jsonStr);
      } catch (_) {}
    }
    return const SecurityPrefs();
  }

  void updatePrefs(SecurityPrefs newPrefs) {
    state = newPrefs;
    _prefs.setString(_key, newPrefs.toJson());
  }

  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: _pinKey, value: hash);
    updatePrefs(state.copyWith(isLockEnabled: true));
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  Future<bool> hasPinSet() async {
    final storedHash = await _secureStorage.read(key: _pinKey);
    return storedHash != null && storedHash.isNotEmpty;
  }

  Future<void> removePin() async {
    await _secureStorage.delete(key: _pinKey);
    updatePrefs(state.copyWith(isLockEnabled: false));
  }

  void toggleIncognito(bool enabled) {
    updatePrefs(state.copyWith(incognitoMode: enabled));
  }

  String _hashPin(String pin) {
    // Deterministic hash with salt
    const salt = 'shonenx_security_salt_2026';
    final bytes = utf8.encode('$salt$pin$salt');
    int hash = 0x811c9dc5;
    for (var byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}

class AppLockState {
  final bool isLocked;
  final DateTime? lastBackgrounded;

  const AppLockState({
    required this.isLocked,
    this.lastBackgrounded,
  });

  AppLockState copyWith({
    bool? isLocked,
    DateTime? lastBackgrounded,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      lastBackgrounded: lastBackgrounded ?? this.lastBackgrounded,
    );
  }
}

final appLockStateProvider =
    NotifierProvider<AppLockStateNotifier, AppLockState>(
      AppLockStateNotifier.new,
    );

class AppLockStateNotifier extends Notifier<AppLockState> {
  @override
  AppLockState build() {
    final prefs = ref.watch(securityPrefsProvider);
    return AppLockState(isLocked: prefs.isLockEnabled);
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }

  void lock() {
    final prefs = ref.read(securityPrefsProvider);
    if (prefs.isLockEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  void onAppPaused() {
    state = state.copyWith(lastBackgrounded: DateTime.now());
  }

  void onAppResumed() {
    final prefs = ref.read(securityPrefsProvider);
    if (!prefs.isLockEnabled) return;

    final lastBg = state.lastBackgrounded;
    if (lastBg == null) {
      lock();
      return;
    }

    final diffSeconds = DateTime.now().difference(lastBg).inSeconds;
    if (diffSeconds >= prefs.autoLockDelaySeconds) {
      lock();
    }
  }
}
