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
    bool resetSeason = false,
    int? year,
    bool resetYear = false,
    String? format,
    bool resetFormat = false,
    String? status,
    bool resetStatus = false,
    String? sort,
    bool resetSort = false,
    List<String>? tags,
  }) {
    return SearchFilter(
      genres: genres ?? this.genres,
      season: resetSeason ? null : (season ?? this.season),
      year: resetYear ? null : (year ?? this.year),
      format: resetFormat ? null : (format ?? this.format),
      status: resetStatus ? null : (status ?? this.status),
      sort: resetSort ? null : (sort ?? this.sort),
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
