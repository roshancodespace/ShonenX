import 'package:flutter/material.dart';

class ShonenXGridView extends StatelessWidget {
  final ScrollController? controller;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int? crossAxisCount;
  final double? crossAxisExtent;
  final ScrollPhysics physics;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets padding;

  const ShonenXGridView({
    super.key,
    this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.physics = const NeverScrollableScrollPhysics(),
    this.crossAxisCount,
    this.crossAxisExtent,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding = const EdgeInsets.all(0.0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          controller: controller,
          shrinkWrap: physics == const NeverScrollableScrollPhysics()
              ? true
              : false,
          physics: physics,
          padding: padding,
          gridDelegate: crossAxisExtent != null
              ? SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: crossAxisExtent!,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  childAspectRatio: childAspectRatio,
                )
              : SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount ?? 2,
                  mainAxisSpacing: mainAxisSpacing,
                  crossAxisSpacing: crossAxisSpacing,
                  childAspectRatio: childAspectRatio,
                ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
