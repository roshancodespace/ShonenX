import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/home/view/widget/search_model.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/widgets/app_scale.dart';
import 'package:shonenx/shared/widgets/focusable_tap.dart';

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

class ActionPanel extends StatefulWidget {
  final bool isDesktop;

  const ActionPanel({super.key, required this.isDesktop});

  @override
  State<ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends State<ActionPanel> {
  final FocusNode _focusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = AppScaleScope.of(context);
    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: false,
      shortcuts: {
        for (final key in _alphaNumericKeys)
          LogicalKeySet(key): const OpenSearchIntent(),
      },
      actions: {
        OpenSearchIntent: CallbackAction<OpenSearchIntent>(
          onInvoke: (_) {
            showSearchModal(context);
            return null;
          },
        ),
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isDesktop) ...[
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: _ActionButton(
                icon: Iconsax.search_normal,
                onTap: () => showSearchModal(context),
                autofocus: true,
                scale: scale,
              ),
            ),
            SizedBox(width: 10 * scale),
          ],
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: _ActionButton(
              icon: Iconsax.setting_2,
              route: '/settings',
              scale: scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final bool autofocus;
  final double scale;

  const _ActionButton({
    required this.icon,
    this.route,
    this.onTap,
    this.autofocus = false,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16 * scale);
    final action = onTap ?? (route != null ? () => context.push(route!) : null);

    return FocusableTap(
      onTap: action,
      autofocus: autofocus,
      borderRadius: radius,
      child: Material(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.all(12 * scale),
          child: Icon(
            icon,
            color: theme.colorScheme.secondary,
            size: 24 * scale,
          ),
        ),
      ),
    );
  }
}

final List<LogicalKeyboardKey> _alphaNumericKeys = [
  // Letters
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyB,
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyD,
  LogicalKeyboardKey.keyE,
  LogicalKeyboardKey.keyF,
  LogicalKeyboardKey.keyG,
  LogicalKeyboardKey.keyH,
  LogicalKeyboardKey.keyI,
  LogicalKeyboardKey.keyJ,
  LogicalKeyboardKey.keyK,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.keyM,
  LogicalKeyboardKey.keyN,
  LogicalKeyboardKey.keyO,
  LogicalKeyboardKey.keyP,
  LogicalKeyboardKey.keyQ,
  LogicalKeyboardKey.keyR,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.keyT,
  LogicalKeyboardKey.keyU,
  LogicalKeyboardKey.keyV,
  LogicalKeyboardKey.keyW,
  LogicalKeyboardKey.keyX,
  LogicalKeyboardKey.keyY,
  LogicalKeyboardKey.keyZ,

  // Numbers
  LogicalKeyboardKey.digit0,
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

