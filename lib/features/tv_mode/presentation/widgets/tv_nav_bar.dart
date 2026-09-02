import 'package:flutter/material.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';

import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class TvNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const TvNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          children: [
            Text(
              'ShonenX TV',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 32),
            _TvTabItem(
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            const SizedBox(width: 12),
            _TvTabItem(
              label: 'Discover',
              isSelected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(width: 12),
            _TvTabItem(
              label: 'Library',
              isSelected: selectedIndex == 2,
              onTap: () => onTabSelected(2),
            ),
            const SizedBox(width: 12),
            _TvTabItem(
              label: 'Settings',
              isSelected: false,
              onTap: () => context.pushSettings(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TvTabItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvTabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvTabItem> createState() => _TvTabItemState();
}

class _TvTabItemState extends State<_TvTabItem> {
  @override
  Widget build(BuildContext context) {
    final cs = ColorScheme.of(context);
    final radius = GlobalUI.uiRoundness;
    return AppFocusHover(
      onTap: widget.onTap,
      builder: (context, isFocused, isHovered) {
        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isFocused
                  ? cs.onSurface
                  : widget.isSelected
                  ? cs.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              border: isFocused
                  ? Border.all(
                      color: cs.primary,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    )
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: isFocused
                    ? cs.surface
                    : widget.isSelected
                    ? cs.onPrimary
                    : cs.onSurfaceVariant,
                fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
