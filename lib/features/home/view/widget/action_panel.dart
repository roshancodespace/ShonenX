import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/home/view/widget/search_model.dart';
import 'package:go_router/go_router.dart';

class ActionPanel extends StatelessWidget {
  final bool isDesktop;

  const ActionPanel({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
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
