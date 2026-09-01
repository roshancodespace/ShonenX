import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/security_service.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

enum LockTimeout {
  immediately('Immediately', Duration.zero),
  after30Seconds('After 30 seconds', Duration(seconds: 30)),
  after1Minute('After 1 minute', Duration(minutes: 1)),
  after5Minutes('After 5 minutes', Duration(minutes: 5)),
  after15Minutes('After 15 minutes', Duration(minutes: 15)),
  onAppRestart('On app restart only', null);

  final String label;
  final Duration? duration;
  const LockTimeout(this.label, this.duration);
}

class SecurityPrefs {
  final bool isAppLockEnabled;
  final bool useBiometrics;
  final bool hasPin;
  final bool autoPromptBiometrics;
  final LockTimeout lockTimeout;
  final bool incognitoMode;

  const SecurityPrefs({
    this.isAppLockEnabled = false,
    this.useBiometrics = false,
    this.hasPin = false,
    this.autoPromptBiometrics = true,
    this.lockTimeout = LockTimeout.immediately,
    this.incognitoMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'isAppLockEnabled': isAppLockEnabled,
      'useBiometrics': useBiometrics,
      'autoPromptBiometrics': autoPromptBiometrics,
      'lockTimeout': lockTimeout.name,
      'incognitoMode': incognitoMode,
    };
  }

  factory SecurityPrefs.fromJson(
    Map<String, dynamic> json, {
    bool hasPin = false,
  }) {
    return SecurityPrefs(
      isAppLockEnabled: json['isAppLockEnabled'] as bool? ?? false,
      useBiometrics: json['useBiometrics'] as bool? ?? false,
      hasPin: hasPin,
      autoPromptBiometrics: json['autoPromptBiometrics'] as bool? ?? true,
      lockTimeout: LockTimeout.values.firstWhere(
        (e) => e.name == json['lockTimeout'],
        orElse: () => LockTimeout.immediately,
      ),
      incognitoMode: json['incognitoMode'] as bool? ?? false,
    );
  }

  SecurityPrefs copyWith({
    bool? isAppLockEnabled,
    bool? useBiometrics,
    bool? hasPin,
    bool? autoPromptBiometrics,
    LockTimeout? lockTimeout,
    bool? incognitoMode,
  }) {
    return SecurityPrefs(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      hasPin: hasPin ?? this.hasPin,
      autoPromptBiometrics: autoPromptBiometrics ?? this.autoPromptBiometrics,
      lockTimeout: lockTimeout ?? this.lockTimeout,
      incognitoMode: incognitoMode ?? this.incognitoMode,
    );
  }
}

class SecurityPrefsNotifier extends Notifier<SecurityPrefs> {
  static const _keyPrefs = 'security_prefs';

  @override
  SecurityPrefs build() {
    final storage = ref.watch(sharedPreferencesProvider);
    final jsonStr = storage.getString(_keyPrefs);
    SecurityPrefs prefs = const SecurityPrefs();

    if (jsonStr != null) {
      try {
        prefs = SecurityPrefs.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }

    _loadPinStatus();

    return prefs;
  }

  Future<void> _loadPinStatus() async {
    final securityService = ref.read(securityServiceProvider);
    final hasPin = await securityService.hasPin();
    if (state.hasPin != hasPin) {
      state = state.copyWith(hasPin: hasPin);
    }
  }

  Future<void> _savePrefs(SecurityPrefs prefs) async {
    state = prefs;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_keyPrefs, jsonEncode(prefs.toJson()));
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _savePrefs(state.copyWith(isAppLockEnabled: enabled));
  }

  Future<void> setUseBiometrics(bool use) async {
    await _savePrefs(state.copyWith(useBiometrics: use));
  }

  Future<void> setAutoPromptBiometrics(bool autoPrompt) async {
    await _savePrefs(state.copyWith(autoPromptBiometrics: autoPrompt));
  }

  Future<void> setLockTimeout(LockTimeout timeout) async {
    await _savePrefs(state.copyWith(lockTimeout: timeout));
  }

  Future<void> setIncognitoMode(bool incognito) async {
    await _savePrefs(state.copyWith(incognitoMode: incognito));
  }

  Future<void> refreshPinStatus() async {
    final securityService = ref.read(securityServiceProvider);
    final hasPin = await securityService.hasPin();
    state = state.copyWith(hasPin: hasPin);
  }

  Future<void> disableAppLock() async {
    final securityService = ref.read(securityServiceProvider);
    await securityService.removePin();
    await _savePrefs(
      state.copyWith(
        isAppLockEnabled: false,
        useBiometrics: false,
        hasPin: false,
      ),
    );
  }
}

final securityPrefsProvider =
    NotifierProvider<SecurityPrefsNotifier, SecurityPrefs>(
      () => SecurityPrefsNotifier(),
    );
