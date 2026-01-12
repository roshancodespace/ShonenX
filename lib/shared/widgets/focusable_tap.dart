import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusableTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool autofocus;
  final Color? focusBorderColor;
  final double focusBorderWidth;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;

  const FocusableTap({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.autofocus = false,
    this.focusBorderColor,
    this.focusBorderWidth = 2,
    this.onFocusChange,
    this.focusNode,
  });

  @override
  State<FocusableTap> createState() => _FocusableTapState();
}

class _FocusableTapState extends State<FocusableTap> {
  bool _focused = false;

  void _handleFocus(bool focused) {
    if (_focused == focused) return;
    setState(() => _focused = focused);
    widget.onFocusChange?.call(focused);
    if (focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final scrollable = Scrollable.maybeOf(context);
        if (scrollable == null) return;
        if (scrollable.position.axis != Axis.vertical) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusBorderColor ??
        Theme.of(context).colorScheme.primary.withOpacity(0.8);

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      enabled: widget.onTap != null,
      onFocusChange: _handleFocus,
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: _focused
            ? BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: focusColor,
                  width: widget.focusBorderWidth,
                ),
              )
            : null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            canRequestFocus: false,
            focusColor: focusColor.withOpacity(0.15),
            hoverColor: focusColor.withOpacity(0.08),
            borderRadius: widget.borderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
