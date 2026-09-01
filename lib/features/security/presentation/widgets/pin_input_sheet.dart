import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/security_service.dart';
import 'package:shonenx/features/security/presentation/widgets/pin_dots_indicator.dart';
import 'package:shonenx/features/security/presentation/widgets/pin_keypad.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';

enum PinFlowType { setup, change, verify, remove }

class PinInputSheet extends ConsumerStatefulWidget {
  final PinFlowType flowType;
  final String? customTitle;
  final String? customSubtitle;

  const PinInputSheet({
    super.key,
    required this.flowType,
    this.customTitle,
    this.customSubtitle,
  });

  static Future<bool?> show({
    required BuildContext context,
    required PinFlowType flowType,
    String? customTitle,
    String? customSubtitle,
  }) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      return AppDialog.show<bool>(
        context: context,
        maxWidth: 360,
        contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        wrapScrollable: false,
        showCloseButton: true,
        child: PinInputSheet(
          flowType: flowType,
          customTitle: customTitle,
          customSubtitle: customSubtitle,
        ),
      );
    }

    return AppBottomSheet.show<bool>(
      context: context,
      title: '',
      contentPadding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: PinInputSheet(
        flowType: flowType,
        customTitle: customTitle,
        customSubtitle: customSubtitle,
      ),
    );
  }

  @override
  ConsumerState<PinInputSheet> createState() => _PinInputSheetState();
}

class _PinInputSheetState extends ConsumerState<PinInputSheet> {
  static const _pinLength = 4;

  String _enteredPin = '';
  String _firstEnteredPin = '';
  int _step = 0;
  bool _hasError = false;
  String? _errorMessage;
  bool _isProcessing = false;

  String get _title {
    if (widget.customTitle != null && _step == 0) return widget.customTitle!;

    switch (widget.flowType) {
      case PinFlowType.setup:
        return _step == 0 ? 'Create PIN' : 'Confirm PIN';
      case PinFlowType.change:
        if (_step == 0) return 'Current PIN';
        if (_step == 1) return 'New PIN';
        return 'Confirm New PIN';
      case PinFlowType.verify:
        return 'Verify PIN';
      case PinFlowType.remove:
        return 'Enter PIN';
    }
  }

  String get _subtitle {
    if (widget.customSubtitle != null && _step == 0) {
      return widget.customSubtitle!;
    }

    switch (widget.flowType) {
      case PinFlowType.setup:
        return _step == 0
            ? 'Enter a 4-digit PIN'
            : 'Re-enter your 4-digit PIN to confirm';
      case PinFlowType.change:
        if (_step == 0) return 'Enter your current PIN to continue';
        if (_step == 1) return 'Enter your new 4-digit PIN';
        return 'Re-enter your new PIN to confirm';
      case PinFlowType.verify:
        return 'Enter your PIN to proceed';
      case PinFlowType.remove:
        return 'Enter your PIN to reset security settings';
    }
  }

  int get _totalSteps {
    switch (widget.flowType) {
      case PinFlowType.setup:
        return 2;
      case PinFlowType.change:
        return 3;
      case PinFlowType.verify:
      case PinFlowType.remove:
        return 1;
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
      _handlePinCompletion(_enteredPin);
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

  Future<void> _handlePinCompletion(String pin) async {
    _isProcessing = true;
    final securityService = ref.read(securityServiceProvider);

    try {
      switch (widget.flowType) {
        case PinFlowType.setup:
          if (_step == 0) {
            setState(() {
              _firstEnteredPin = pin;
              _enteredPin = '';
              _step = 1;
              _isProcessing = false;
            });
          } else {
            if (pin == _firstEnteredPin) {
              await securityService.setPin(pin);
              if (mounted) Navigator.of(context).pop(true);
            } else {
              _showError('PINs do not match. Try again.');
            }
          }
          break;

        case PinFlowType.change:
          if (_step == 0) {
            final isValid = await securityService.verifyPin(pin);
            if (isValid) {
              setState(() {
                _enteredPin = '';
                _step = 1;
                _isProcessing = false;
              });
            } else {
              _showError('Incorrect current PIN');
            }
          } else if (_step == 1) {
            setState(() {
              _firstEnteredPin = pin;
              _enteredPin = '';
              _step = 2;
              _isProcessing = false;
            });
          } else {
            if (pin == _firstEnteredPin) {
              await securityService.setPin(pin);
              if (mounted) Navigator.of(context).pop(true);
            } else {
              _showError('PINs do not match. Try again.');
            }
          }
          break;

        case PinFlowType.verify:
        case PinFlowType.remove:
          final isValid = await securityService.verifyPin(pin);
          if (isValid) {
            if (widget.flowType == PinFlowType.remove) {
              await securityService.removePin();
            }
            if (mounted) Navigator.of(context).pop(true);
          } else {
            _showError('Incorrect PIN. Please try again.');
          }
          break;
      }
    } finally {
      if (mounted && _hasError) {
        _isProcessing = false;
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _enteredPin = '';
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_totalSteps > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (index) {
              final isStepActive = index <= _step;
              return Container(
                width: 24,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isStepActive
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.35),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
        ],

        // Lock icon badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.lock_outline_rounded, size: 22, color: cs.primary),
        ),

        const SizedBox(height: 10),

        // Title & Subtitle
        Text(
          _title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _subtitle,
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        // PIN Dots
        PinDotsIndicator(
          pinLength: _pinLength,
          enteredLength: _enteredPin.length,
          hasError: _hasError,
          errorText: _errorMessage,
        ),

        const SizedBox(height: 20),

        // Keypad
        PinKeypad(
          buttonSize: size.height < 650 ? 56 : 64,
          onDigitPressed: _onDigitPressed,
          onDeletePressed: _onDeletePressed,
        ),
      ],
    );
  }
}
