import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'filtered_discover_screen.dart';
import 'search_discover_screen.dart';

class DiscoverScreen extends StatelessWidget {
  final String? query;
  final String? category;
  final MediaType type;
  final List<String> genres;
  final List<String> tags;
  final String? source;

  const DiscoverScreen({
    super.key,
    this.query,
    this.category,
    this.type = MediaType.ANIME,
    this.genres = const [],
    this.tags = const [],
    this.source,
  });

  bool get hasCategory => category != null && category!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (hasCategory) {
      return FilteredDiscoverScreen(category: category!, type: type);
    }

    return SearchDiscoverScreen(
      initialQuery: query,
      type: type,
      initialGenres: genres,
      initialTags: tags,
      source: source,
    );
  }
}
