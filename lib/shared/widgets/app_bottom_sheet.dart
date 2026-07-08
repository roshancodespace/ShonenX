import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry contentPadding;
  final List<Widget>? actions;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.contentPadding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool enableDrag = true,
    bool useSafeArea = true,
    EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(
      horizontal: 16,
    ),
    EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(
      16,
      0,
      16,
      16,
    ),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 380),
        reverseDuration: const Duration(milliseconds: 280),
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (_) {
        return AppBottomSheet(
          title: title,
          actions: actions,
          headerPadding: headerPadding,
          contentPadding: contentPadding,
          child: child,
        );
      },
    );
  }

  static Future<T?> showSelector<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T item) itemLabel,
    required void Function(T item) onChanged,
    T? selectedValue,
    List<Widget>? actions,
    Widget? Function(T item)? badgeBuilder,
    Widget? Function(T item, bool isSelected)? leadingBuilder,
    Widget? Function(T item, bool isSelected)? trailingBuilder,
    String? Function(T item)? subtitleBuilder,
    bool closeOnSelect = true,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool enableDrag = true,
    bool useSafeArea = true,
    EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(
      horizontal: 16,
    ),
    EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(
      16,
      0,
      16,
      16,
    ),
  }) {
    return show<T>(
      context: context,
      title: title,
      actions: actions,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      headerPadding: headerPadding,
      contentPadding: contentPadding,
      child: Builder(
        builder: (sheetContext) {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item == selectedValue;
              final subtitle = subtitleBuilder?.call(item);
              return ListTile(
                selected: isSelected,
                selectedTileColor: Theme.of(
                  sheetContext,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading:
                    leadingBuilder?.call(item, isSelected) ??
                    (isSelected
                        ? Icon(
                            Icons.radio_button_checked_rounded,
                            color: Theme.of(sheetContext).colorScheme.primary,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: Theme.of(
                              sheetContext,
                            ).colorScheme.onSurfaceVariant,
                          )),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        itemLabel(item),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(sheetContext).colorScheme.primary
                              : Theme.of(sheetContext).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (badgeBuilder != null) ...[
                      const SizedBox(width: 8),
                      badgeBuilder(item)!,
                    ],
                  ],
                ),
                subtitle: subtitle != null
                    ? Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            sheetContext,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing:
                    trailingBuilder?.call(item, isSelected) ??
                    (isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: Theme.of(sheetContext).colorScheme.primary,
                          )
                        : null),
                onTap: () {
                  onChanged(item);

                  if (closeOnSelect) {
                    sheetContext.pop(item);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.32, end: 0.0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        builder: (context, tilt, child) {
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateX(tilt),
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(GlobalUI.uiRoundness),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: headerPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actions != null) ...[
                      ...actions!,
                      const SizedBox(width: 8),
                    ],
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Padding(padding: contentPadding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
