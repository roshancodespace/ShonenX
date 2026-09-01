import 'dart:convert';

class SecurityPrefs {
  final bool isLockEnabled;
  final bool useBiometrics;
  final int autoLockDelaySeconds;
  final bool incognitoMode;
  final bool hideContentInAppSwitcher;

  const SecurityPrefs({
    this.isLockEnabled = false,
    this.useBiometrics = true,
    this.autoLockDelaySeconds = 0,
    this.incognitoMode = false,
    this.hideContentInAppSwitcher = true,
  });

  SecurityPrefs copyWith({
    bool? isLockEnabled,
    bool? useBiometrics,
    int? autoLockDelaySeconds,
    bool? incognitoMode,
    bool? hideContentInAppSwitcher,
  }) {
    return SecurityPrefs(
      isLockEnabled: isLockEnabled ?? this.isLockEnabled,
      useBiometrics: useBiometrics ?? this.useBiometrics,
      autoLockDelaySeconds: autoLockDelaySeconds ?? this.autoLockDelaySeconds,
      incognitoMode: incognitoMode ?? this.incognitoMode,
      hideContentInAppSwitcher:
          hideContentInAppSwitcher ?? this.hideContentInAppSwitcher,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isLockEnabled': isLockEnabled,
      'useBiometrics': useBiometrics,
      'autoLockDelaySeconds': autoLockDelaySeconds,
      'incognitoMode': incognitoMode,
      'hideContentInAppSwitcher': hideContentInAppSwitcher,
    };
  }

  factory SecurityPrefs.fromMap(Map<String, dynamic> map) {
    return SecurityPrefs(
      isLockEnabled: map['isLockEnabled'] as bool? ?? false,
      useBiometrics: map['useBiometrics'] as bool? ?? true,
      autoLockDelaySeconds: map['autoLockDelaySeconds'] as int? ?? 0,
      incognitoMode: map['incognitoMode'] as bool? ?? false,
      hideContentInAppSwitcher: map['hideContentInAppSwitcher'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory SecurityPrefs.fromJson(String source) =>
      SecurityPrefs.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
