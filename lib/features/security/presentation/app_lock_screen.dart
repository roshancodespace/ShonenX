import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/security_service.dart';
import 'package:shonenx/features/security/presentation/widgets/pin_dots_indicator.dart';
import 'package:shonenx/features/security/presentation/widgets/pin_keypad.dart';
import 'package:shonenx/shared/providers/app_lock_provider.dart';
import 'package:shonenx/shared/providers/security_prefs_provider.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  static const _pinLength = 4;
  String _enteredPin = '';
  bool _hasError = false;
  String? _errorMessage;
  bool _isProcessing = false;
  final FocusNode _keyboardFocusNode = FocusNode();

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMobile) {
        _checkAutoBiometrics();
      }
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAutoBiometrics() async {
    final prefs = ref.read(securityPrefsProvider);
    if (_isMobile && prefs.useBiometrics && prefs.autoPromptBiometrics) {
      await _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!_isMobile || _isProcessing) return;
    final securityService = ref.read(securityServiceProvider);

    setState(() => _isProcessing = true);
    try {
      final success = await securityService.authenticateBiometrics(
        reason: 'Authenticate to unlock ShonenX',
      );

      if (success && mounted) {
        ref.read(appLockProvider.notifier).unlock();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _onDigitPressed(String digit) {
    if (_isProcessing || _enteredPin.length >= _pinLength) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == _pinLength) {
      _verifyPin(_enteredPin);
    }
  }

  void _onDeletePressed() {
    if (_isProcessing || _enteredPin.isEmpty) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _verifyPin(String pin) async {
    setState(() => _isProcessing = true);
    final securityService = ref.read(securityServiceProvider);

    try {
      final isValid = await securityService.verifyPin(pin);

      if (isValid && mounted) {
        HapticFeedback.mediumImpact();
        ref.read(appLockProvider.notifier).unlock();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _hasError = true;
          _errorMessage = 'Incorrect PIN';
          _enteredPin = '';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error verifying PIN';
        _enteredPin = '';
        _isProcessing = false;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final char = event.character;
      if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
        _onDigitPressed(char);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _onDeletePressed();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = ref.watch(securityPrefsProvider);
    final size = MediaQuery.of(context).size;
    final hasBiometrics = _isMobile && prefs.useBiometrics;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Lock Emblem Header
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.25),
                          cs.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 36,
                      color: cs.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'ShonenX',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: cs.onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Enter PIN to unlock',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),

                  const SizedBox(height: 32),

                  // PIN Dots
                  PinDotsIndicator(
                    pinLength: _pinLength,
                    enteredLength: _enteredPin.length,
                    hasError: _hasError,
                    errorText: _errorMessage,
                  ),

                  const SizedBox(height: 36),

                  // Keypad
                  PinKeypad(
                    buttonSize: size.height < 650 ? 62 : 72,
                    showBiometricButton: hasBiometrics,
                    onDigitPressed: _onDigitPressed,
                    onDeletePressed: _onDeletePressed,
                    onBiometricPressed: _authenticateWithBiometrics,
                  ),

                  if (hasBiometrics) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : _authenticateWithBiometrics,
                      icon: const Icon(Icons.fingerprint_rounded, size: 20),
                      label: const Text('Unlock with Biometrics'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
