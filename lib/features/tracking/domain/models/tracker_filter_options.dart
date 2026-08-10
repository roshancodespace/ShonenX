import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';

class TrackerFilterOptions {
  final List<String> genres;
  final List<String> tags;
  final List<SearchSort> sorts;
  final List<SearchStatusFilter> statuses;
  final List<SearchFormatFilter> formats;

  const TrackerFilterOptions({
    this.genres = const [],
    this.tags = const [],
    this.sorts = SearchSort.values,
    this.statuses = SearchStatusFilter.values,
    this.formats = SearchFormatFilter.values,
  });

  bool get supportsGenres => genres.isNotEmpty;
  bool get supportsTags => tags.isNotEmpty;
  bool get supportsSorts => sorts.length > 1;
  bool get supportsStatuses => statuses.length > 1;
  bool get supportsFormats => formats.length > 1;

  bool get hasAnyFilter =>
      supportsGenres ||
      supportsTags ||
      supportsSorts ||
      supportsStatuses ||
      supportsFormats;

  static const none = TrackerFilterOptions(
    genres: [],
    tags: [],
    sorts: [],
    statuses: [],
    formats: [],
  );
}
