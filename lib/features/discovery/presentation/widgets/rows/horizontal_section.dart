import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HorizontalSection<T> extends StatelessWidget {
  final String title;
  final AsyncValue<List<T>> data;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final double height;
  final String emptyText;
  final double? gap;
  final VoidCallback? onMoreTap;
  final Widget Function(BuildContext context, int index)? skeletonItemBuilder;
  final int skeletonCount;

  const HorizontalSection({
    super.key,
    required this.title,
    required this.data,
    required this.itemBuilder,
    required this.height,
    this.gap,
    this.emptyText = 'No data found',
    this.onMoreTap,
    this.skeletonItemBuilder,
    this.skeletonCount = 25,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (onMoreTap != null) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: onMoreTap,
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: data.when(
            loading: () => Skeletonizer(
              enabled: true,
              child: ListView.separated(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                return Center(
                  child: Text(
                    emptyText,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.separated(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    itemBuilder(context, items[index]),
                separatorBuilder: (context, index) =>
                    SizedBox(width: gap ?? 10.0),
              );
            },
          ),
        ),
      ],
    );
  }
}
