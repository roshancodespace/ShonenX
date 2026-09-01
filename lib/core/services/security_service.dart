import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shonenx/core/network/secure_storage.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class BiometricCapability {
  final bool isSupported;
  final bool canCheckBiometrics;
  final List<BiometricType> enrolledTypes;

  const BiometricCapability({
    required this.isSupported,
    required this.canCheckBiometrics,
    required this.enrolledTypes,
  });

  bool get canAuthenticate =>
      isSupported && (canCheckBiometrics || enrolledTypes.isNotEmpty);

  String get hardwareDescription {
    if (!isSupported) return 'Not supported on this device';
    if (enrolledTypes.isEmpty) return 'No biometrics enrolled on device';

    final names = enrolledTypes
        .map((type) {
          switch (type) {
            case BiometricType.fingerprint:
              return 'Fingerprint';
            case BiometricType.face:
              return 'Face ID';
            case BiometricType.iris:
              return 'Iris';
            case BiometricType.strong:
              return 'Biometrics';
            case BiometricType.weak:
              return 'Device Credentials';
          }
        })
        .toSet()
        .toList();

    return names.join(' / ');
  }
}

class SecurityService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;
  static final _log = AppLogger.scope('SecurityService');

  static const _pinSaltKey = 'security_pin_salt';
  static const _pinHashKey = 'security_pin_hash';

  SecurityService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<BiometricCapability> getBiometricCapability() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const BiometricCapability(
        isSupported: false,
        canCheckBiometrics: false,
        enrolledTypes: [],
      );
    }

    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final types = isSupported
          ? await _localAuth.getAvailableBiometrics()
          : <BiometricType>[];

      return BiometricCapability(
        isSupported: isSupported,
        canCheckBiometrics: canCheck,
        enrolledTypes: types,
      );
    } catch (e, st) {
      _log.e('Failed to get biometric capability: $e', e, st);
      return const BiometricCapability(
        isSupported: false,
        canCheckBiometrics: false,
        enrolledTypes: [],
      );
    }
  }

  Future<bool> authenticateBiometrics({
    String reason = 'Authenticate to unlock ShonenX',
    bool biometricOnly = true,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    try {
      final canAuth =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuth) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
    } catch (e, st) {
      _log.e('Biometric authentication error: $e', e, st);
      return false;
    }
  }

  Future<void> cancelBiometricAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {}
  }

  Future<bool> hasPin() async {
    try {
      final hash = await _secureStorage.read(key: _pinHashKey);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      _log.e('Error checking PIN presence: $e');
      return false;
    }
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  Future<bool> setPin(String pin) async {
    try {
      if (pin.length < 4) return false;
      final random = Random.secure();
      final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
      final salt = base64Encode(saltBytes);
      final hash = _hashPin(pin, salt);

      await _secureStorage.write(key: _pinSaltKey, value: salt);
      await _secureStorage.write(key: _pinHashKey, value: hash);
      return true;
    } catch (e, st) {
      _log.e('Failed to set PIN: $e', e, st);
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final salt = await _secureStorage.read(key: _pinSaltKey);
      final storedHash = await _secureStorage.read(key: _pinHashKey);

      if (salt == null || storedHash == null) return false;

      final calculatedHash = _hashPin(pin, salt);
      return calculatedHash == storedHash;
    } catch (e) {
      _log.e('Error verifying PIN: $e');
      return false;
    }
  }

  Future<void> removePin() async {
    try {
      await _secureStorage.delete(key: _pinSaltKey);
      await _secureStorage.delete(key: _pinHashKey);
    } catch (e) {
      _log.e('Error removing PIN: $e');
    }
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SecurityService(
    localAuth: LocalAuthentication(),
    secureStorage: secureStorage,
  );
});

final biometricCapabilityProvider = FutureProvider<BiometricCapability>((
  ref,
) async {
  final securityService = ref.watch(securityServiceProvider);
  return securityService.getBiometricCapability();
});
