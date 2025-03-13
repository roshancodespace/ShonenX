import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/utils/theme.dart';

class SettingsSection extends StatelessWidget {
  final BuildContext context;
  final String title;
  final List<Widget> items;

  const SettingsSection({
    super.key,
    required this.context,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                      ?.borderRadius ??
                  BorderRadius.circular(8),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    item,
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool disabled;
  final Widget? trailing; // Added trailing widget option

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.disabled = false,
    this.trailing, // Added trailing widget parameter
  });

  @override
  State<SettingsItem> createState() => _SettingsItemState();
}

class _SettingsItemState extends State<SettingsItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: getCardBorderRadius(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered && !widget.disabled
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: (theme.cardTheme.shape as RoundedRectangleBorder?)
                    ?.borderRadius ??
                BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: widget.disabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.disabled
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              widget.trailing != null
                  ? widget.trailing!
                  : Icon(
                      Iconsax.arrow_right_3,
                      size: 20,
                      color: widget.disabled
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
