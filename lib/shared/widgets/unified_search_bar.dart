import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class UnifiedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBackPressed;
  final VoidCallback onClearPressed;
  final VoidCallback? onFilterPressed;
  final ValueChanged<String>? onSubmitted;
  final bool hasFilters;
  final String hintText;
  final bool autofocus;
  final Widget? leading;

  const UnifiedSearchBar({
    super.key,
    required this.controller,
    required this.onBackPressed,
    required this.onClearPressed,
    this.onFilterPressed,
    this.onSubmitted,
    this.hasFilters = false,
    this.hintText = 'Search anime or manga...',
    this.autofocus = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onPrimaryContainer;
    final iconColor = colorScheme.onPrimaryContainer;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          margin: const EdgeInsetsDirectional.all(4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(GlobalUI.uiRoundness * 1.3),
            border: Border.all(
              color: colorScheme.primary,
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 4),
              leading != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: IconTheme(
                        data: IconThemeData(color: iconColor, size: 20),
                        child: leading!,
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 16,
                        color: iconColor,
                      ),
                      tooltip: 'Back',
                      onPressed: onBackPressed,
                    ),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    hintText: hintText,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: iconColor),
                  tooltip: 'Clear search',
                  onPressed: onClearPressed,
                ),
              if (hasFilters && onFilterPressed != null)
                IconButton(
                  icon: Icon(Icons.tune_rounded, size: 18, color: iconColor),
                  tooltip: 'Filters',
                  onPressed: onFilterPressed,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
