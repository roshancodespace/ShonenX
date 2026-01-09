class SearchFilter {
  final List<String> genres;
  final String? season;
  final int? year;
  final String? format;
  final String? status;
  final String? sort;
  final List<String> tags;

  const SearchFilter({
    this.genres = const [],
    this.season,
    this.year,
    this.format,
    this.status,
    this.sort,
    this.tags = const [],
  });

  SearchFilter copyWith({
    List<String>? genres,
    String? season,
    int? year,
    String? format,
    String? status,
    String? sort,
    List<String>? tags,
  }) {
    return SearchFilter(
      genres: genres ?? this.genres,
      season: season ?? this.season,
      year: year ?? this.year,
      format: format ?? this.format,
      status: status ?? this.status,
      sort: sort ?? this.sort,
      tags: tags ?? this.tags,
    );
  }

  bool get isEmpty =>
      genres.isEmpty &&
      season == null &&
      year == null &&
      format == null &&
      status == null &&
      sort == null &&
      tags.isEmpty;

  @override
  String toString() {
    return 'SearchFilter(genres: $genres, season: $season, year: $year, format: $format, status: $status, sort: $sort, tags: $tags)';
  }
}
