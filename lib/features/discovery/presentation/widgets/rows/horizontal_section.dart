import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HorizontalSection<T> extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? headerActions;
  final Widget? headerTrailing;
  final AsyncValue<List<T>> data;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double height;
  final String emptyText;
  final Widget? emptyWidget;
  final double? gap;
  final VoidCallback? onMoreTap;
  final Widget Function(BuildContext context, int index)? skeletonItemBuilder;
  final int skeletonCount;
  final ScrollController? controller;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? listPadding;

  const HorizontalSection({
    super.key,
    this.title,
    this.titleWidget,
    this.headerActions,
    this.headerTrailing,
    required this.data,
    required this.itemBuilder,
    required this.height,
    this.gap,
    this.emptyText = 'No data found',
    this.emptyWidget,
    this.onMoreTap,
    this.skeletonItemBuilder,
    this.skeletonCount = 6,
    this.controller,
    this.headerPadding,
    this.listPadding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleWidget =
        titleWidget ??
        (title != null
            ? Text(title!, style: Theme.of(context).textTheme.titleLarge)
            : const SizedBox.shrink());

    final hasHeader =
        title != null ||
        titleWidget != null ||
        (headerActions != null && headerActions!.isNotEmpty) ||
        headerTrailing != null ||
        onMoreTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasHeader)
          Padding(
            padding:
                headerPadding ??
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: effectiveTitleWidget),
                      if (headerActions != null &&
                          headerActions!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...headerActions!,
                      ],
                    ],
                  ),
                ),
                if (headerTrailing != null) headerTrailing!,
                if (onMoreTap != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: onMoreTap,
                  ),
              ],
            ),
          ),
        SizedBox(
          height: height,
          child: data.when(
            loading: () => Skeletonizer(
              enabled: true,
              child: ListView.separated(
                controller: controller,
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                padding:
                    listPadding ?? const EdgeInsets.symmetric(horizontal: 12),
                itemCount: skeletonCount,
                itemBuilder: (context, index) {
                  if (skeletonItemBuilder != null) {
                    return skeletonItemBuilder!(context, index);
                  }
                  return Container(
                    width: height * 0.7,
                    height: height,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    SizedBox(width: gap ?? 10.0),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return emptyWidget ??
                    Center(
                      child: Text(
                        emptyText,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
              }

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: ListView.separated(
                  controller: controller,
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  padding:
                      listPadding ?? const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Builder(
                      builder: (itemContext) {
                        return Focus(
                          skipTraversal: true,
                          canRequestFocus: false,
                          onFocusChange: (hasFocus) {
                            if (hasFocus) {
                              Scrollable.ensureVisible(
                                itemContext,
                                alignment: 0.5,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: itemBuilder(itemContext, items[index]),
                        );
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      SizedBox(width: gap ?? 10.0),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
