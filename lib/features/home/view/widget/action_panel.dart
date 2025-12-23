import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/home/view/widget/search_model.dart';
import 'package:go_router/go_router.dart';

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

class ActionPanel extends StatelessWidget {
  final bool isDesktop;

  const ActionPanel({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: true,
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
          if (!isDesktop) ...[
            _ActionButton(
              icon: Iconsax.search_normal,
              onTap: () => showSearchModal(context),
            ),
            const SizedBox(width: 10),
          ],
          const _ActionButton(icon: Iconsax.setting_2, route: '/settings'),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap ?? (route != null ? () => context.push(route!) : null),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: theme.colorScheme.secondary),
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

