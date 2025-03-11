import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

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
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
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

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.disabled = false,
  });

  @override
  State<SettingsItem> createState() => SettingsItemState();
}

class SettingsItemState extends State<SettingsItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) {
        if (!widget.disabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (!widget.disabled) {
          setState(() => _isHovered = false);
        }
      },
      child: InkWell(
        onTap: widget.disabled ? null : widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered && !widget.disabled
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary
                          .withValues(alpha: widget.disabled ? 0.05 : 0.2),
                      colorScheme.primary
                          .withValues(alpha: widget.disabled ? 0.03 : 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.disabled
                      ? colorScheme.onSurface.withValues(alpha: 0.4)
                      : colorScheme.primary,
                  size: 20,
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
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface
                            .withValues(alpha: widget.disabled ? 0.3 : 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: colorScheme.onSurface
                    .withValues(alpha: widget.disabled ? 0.2 : 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
