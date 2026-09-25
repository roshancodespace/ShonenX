import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class AppBottomSheet extends ConsumerWidget {
  final String title;
  final Widget child;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry contentPadding;
  final List<Widget>? actions;
  final IconData? titleIcon;
  final bool isFloating;
  final bool? showDragHandle;
  final Color? backgroundColor;
  final double? blurSigma;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.contentPadding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.actions,
    this.titleIcon,
    this.isFloating = false,
    this.showDragHandle,
    this.backgroundColor,
    this.blurSigma,
    this.border,
    this.borderRadius,
    this.margin,
  });

  static const AnimationStyle hammerAnimationStyle = AnimationStyle(
    duration: Duration(milliseconds: 380),
    reverseDuration: Duration(milliseconds: 280),
    curve: Curves.easeOutQuart,
    reverseCurve: Curves.easeInCubic,
  );

  static const AnimationStyle slideUpAnimationStyle = AnimationStyle(
    duration: Duration(milliseconds: 320),
    reverseDuration: Duration(milliseconds: 240),
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    IconData? titleIcon,
    bool isScrollControlled = true,
    bool useRootNavigator = false,
    bool enableDrag = true,
    bool useSafeArea = true,
    bool isFloating = false,
    bool? showDragHandle,
    Color? backgroundColor,
    Color? barrierColor,
    double? blurSigma,
    double maxWidth = 600,
    BoxBorder? border,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? margin,
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
    AnimationStyle? effectiveAnimationStyle;
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final isHammer = container.read(uiPrefsProvider).sheetPhysics;
      effectiveAnimationStyle = isHammer
          ? hammerAnimationStyle
          : slideUpAnimationStyle;
    } catch (_) {
      effectiveAnimationStyle = hammerAnimationStyle;
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
      barrierColor: barrierColor,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      sheetAnimationStyle: effectiveAnimationStyle,
      builder: (_) {
        return AppBottomSheet(
          title: title,
          titleIcon: titleIcon,
          actions: actions,
          headerPadding: headerPadding,
          contentPadding: contentPadding,
          isFloating: isFloating,
          showDragHandle: showDragHandle,
          backgroundColor: backgroundColor,
          blurSigma: blurSigma,
          border: border,
          borderRadius: borderRadius,
          margin: margin,
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
            physics: const BouncingScrollPhysics(),
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
                title: Builder(
                  builder: (context) {
                    final badge = badgeBuilder?.call(item);
                    return Row(
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
                                  : Theme.of(
                                      sheetContext,
                                    ).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (badge != null) ...[const SizedBox(width: 8), badge],
                      ],
                    );
                  },
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
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasTilt = ref.watch(uiPrefsProvider.select((p) => p.sheetPhysics));
    final roundness = GlobalUI.uiRoundness;

    final effectiveShowDragHandle = showDragHandle ?? !isFloating;
    final effectiveBorderRadius =
        borderRadius ??
        (isFloating
            ? BorderRadius.circular(roundness)
            : BorderRadius.vertical(top: Radius.circular(roundness)));

    final effectiveBackgroundColor =
        backgroundColor ??
        (isFloating
            ? cs.surfaceContainerHigh.withValues(alpha: 0.9)
            : cs.surfaceContainer.withValues(alpha: 0.9));

    final effectiveMargin =
        margin ??
        (isFloating
            ? EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16)
            : EdgeInsets.only(bottom: bottomInset));

    final effectiveBorder =
        border ??
        (isFloating
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.35))
            : null);

    final effectiveBlur = blurSigma ?? (isFloating ? 20.0 : null);

    Widget innerContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (effectiveShowDragHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        Padding(
          padding: effectiveShowDragHandle
              ? headerPadding
              : (headerPadding is EdgeInsets
                    ? (headerPadding as EdgeInsets).copyWith(top: 14)
                    : headerPadding),
          child: Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, color: cs.primary, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...[...actions!, const SizedBox(width: 8)],
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  foregroundColor: cs.onSurfaceVariant,
                ),
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: Padding(padding: contentPadding, child: child),
        ),
      ],
    );

    Widget sheetContent;
    if (effectiveBlur != null && effectiveBlur > 0) {
      sheetContent = Container(
        margin: effectiveMargin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: isFloating
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: effectiveBlur,
              sigmaY: effectiveBlur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: effectiveBackgroundColor,
                borderRadius: effectiveBorderRadius,
                border: effectiveBorder,
              ),
              child: innerContent,
            ),
          ),
        ),
      );
    } else {
      sheetContent = Container(
        margin: effectiveMargin,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: effectiveBorderRadius,
          border: effectiveBorder,
          boxShadow: isFloating
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: innerContent,
      );
    }

    if (hasTilt) {
      sheetContent = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.32, end: 0.0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        builder: (ctx, tilt, animatedChild) {
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateX(tilt),
            child: animatedChild,
          );
        },
        child: sheetContent,
      );
    }

    return SafeArea(child: sheetContent);
  }
}
