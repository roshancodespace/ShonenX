import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/security/providers/security_provider.dart';

enum AppLockMode { unlock, setup, confirm }

class AppLockScreen extends ConsumerStatefulWidget {
  final AppLockMode mode;
  final String? initialPin;
  final VoidCallback? onUnlocked;

  const AppLockScreen({
    super.key,
    this.mode = AppLockMode.unlock,
    this.initialPin,
    this.onUnlocked,
  });

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  static const int _pinLength = 4;
  bool _isError = false;
  String _statusMessage = '';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _updateStatusMessage();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _updateStatusMessage() {
    switch (widget.mode) {
      case AppLockMode.unlock:
        _statusMessage = 'Enter PIN to unlock ShonenX';
        break;
      case AppLockMode.setup:
        _statusMessage = 'Create a 4-digit PIN';
        break;
      case AppLockMode.confirm:
        _statusMessage = 'Confirm your 4-digit PIN';
        break;
    }
  }

  void _handleKeyPress(String digit) {
    if (_enteredPin.length >= _pinLength) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == _pinLength) {
      _submitPin();
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  Future<void> _submitPin() async {
    final notifier = ref.read(securityPrefsProvider.notifier);

    if (widget.mode == AppLockMode.unlock) {
      final isValid = await notifier.verifyPin(_enteredPin);
      if (isValid) {
        HapticFeedback.mediumImpact();
        ref.read(appLockStateProvider.notifier).unlock();
        if (widget.onUnlocked != null) {
          widget.onUnlocked!();
        } else if (context.mounted && context.canPop()) {
          context.pop(true);
        }
      } else {
        _triggerError('Incorrect PIN. Please try again.');
      }
    } else if (widget.mode == AppLockMode.setup) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AppLockScreen(
              mode: AppLockMode.confirm,
              initialPin: _enteredPin,
            ),
          ),
        );
      }
    } else if (widget.mode == AppLockMode.confirm) {
      if (_enteredPin == widget.initialPin) {
        await notifier.setPin(_enteredPin);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('App Lock PIN configured successfully!')),
          );
          context.pop(true);
        }
      } else {
        _triggerError('PINs do not match. Please try again.');
      }
    }
  }

  void _triggerError(String msg) {
    HapticFeedback.heavyImpact();
    setState(() {
      _isError = true;
      _statusMessage = msg;
      _enteredPin = '';
    });
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: widget.mode != AppLockMode.unlock,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.mode != AppLockMode.unlock
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(false),
                )
              : null,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              // Header
              Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _isError
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isError
                          ? Icons.lock_clock_rounded
                          : Icons.lock_outline_rounded,
                      size: 36,
                      color: _isError
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ShonenX Security',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _isError
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // PIN Dots
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final sineValue =
                          (1.0 - _shakeController.value) * 12.0 *
                              (1 - 2 * (_shakeController.value * 4 % 1));
                      return Transform.translate(
                        offset: Offset(sineValue, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pinLength,
                        (index) {
                          final isFilled = index < _enteredPin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: isFilled ? 18 : 14,
                            height: isFilled ? 18 : 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isError
                                  ? theme.colorScheme.error
                                  : isFilled
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // Keypad
              Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
                child: Column(
                  children: [
                    _buildRow(['1', '2', '3'], theme),
                    const SizedBox(height: 16),
                    _buildRow(['4', '5', '6'], theme),
                    const SizedBox(height: 16),
                    _buildRow(['7', '8', '9'], theme),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72, height: 72),
                        _buildKey('0', theme),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: IconButton(
                            onPressed: _handleBackspace,
                            icon: const Icon(Icons.backspace_outlined),
                            color: theme.colorScheme.onSurface,
                            iconSize: 26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key, theme)).toList(),
    );
  }

  Widget _buildKey(String label, ThemeData theme) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleKeyPress(label),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
