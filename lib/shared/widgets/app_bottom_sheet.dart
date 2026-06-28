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
    this.contentPadding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool enableDrag = true,
    bool useSafeArea = true,
    EdgeInsetsGeometry headerPadding = const EdgeInsets.symmetric(
      horizontal: 16,
    ),
    EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(
      16,
      12,
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
      builder: (_) {
        return AppBottomSheet(
          title: title,
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
      12,
      16,
      16,
    ),
  }) {
    return show<T>(
      context: context,
      title: title,
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
                leading: leadingBuilder?.call(item, isSelected),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemLabel(item),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badgeBuilder != null) ...[
                      const SizedBox(width: 10),
                      badgeBuilder(item) ?? const SizedBox.shrink(),
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

    return Container(
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
              margin: const EdgeInsets.only(bottom: 16),
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
                if (actions != null) ...[...actions!, const SizedBox(width: 8)],
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
    );
  }
}
