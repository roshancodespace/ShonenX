import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

import 'widgets/discover/category_tab_feed.dart';

class CategoryDiscoverScreen extends ConsumerStatefulWidget {
  final String category;
  final MediaType type;

  const CategoryDiscoverScreen({
    super.key,
    required this.category,
    required this.type,
  });

  @override
  ConsumerState<CategoryDiscoverScreen> createState() =>
      _CategoryDiscoverScreenState();
}

class _CategoryDiscoverScreenState
    extends ConsumerState<CategoryDiscoverScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.category,
      subtitle: 'Browse ${widget.category}',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: CategoryTabFeed(type: widget.type, category: widget.category),
      ),
    );
  }
}
