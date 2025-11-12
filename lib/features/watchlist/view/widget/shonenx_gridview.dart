import 'package:flutter/material.dart';

class ShonenXGridView extends StatelessWidget {
  final ScrollController? controller;
  final List<Widget> items;
  final int crossAxisCount;
  final ScrollPhysics physics;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets padding;

  const ShonenXGridView({
    super.key,
    this.controller,
    required this.items,
    this.physics = const NeverScrollableScrollPhysics(),
    this.crossAxisCount = 2,
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
          shrinkWrap:
              physics == const NeverScrollableScrollPhysics() ? true : false,
          physics: physics,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return items[index];
          },
        );
      },
    );
  }
}
