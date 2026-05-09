import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool enableDrag = true,
    bool useSafeArea = true,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AppBottomSheet(title: title, padding: padding, child: child);
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
    bool closeOnSelect = true,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool enableDrag = true,
    bool useSafeArea = true,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 12, 20, 20),
    Widget? Function(T item, bool isSelected)? trailingBuilder,
  }) {
    return show<T>(
      context: context,
      title: title,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      padding: padding,
      child: Builder(
        builder: (sheetContext) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                final isSelected = item == selectedValue;

                return ListTile(
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
                  trailing:
                      trailingBuilder?.call(item, isSelected) ??
                      (isSelected ? const Icon(Icons.check) : null),
                  onTap: () {
                    onChanged(item);

                    if (closeOnSelect) {
                      sheetContext.pop(item);
                    }
                  },
                );
              }).toList(),
            ),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: padding,
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
            Row(
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
            const SizedBox(height: 16),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
