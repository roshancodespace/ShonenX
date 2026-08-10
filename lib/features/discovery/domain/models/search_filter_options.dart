enum SearchSort {
  popularity('Popularity'),
  newest('Release Date (Newest)'),
  oldest('Release Date (Oldest)'),
  alphabeticalAZ('Alphabetical (A-Z)'),
  alphabeticalZA('Alphabetical (Z-A)');

  final String label;
  const SearchSort(this.label);

  static SearchSort tryFromId(String? id) {
    if (id == null || id.isEmpty) return SearchSort.popularity;
    for (final val in values) {
      if (val.name == id || val.label == id) return val;
    }
    return SearchSort.popularity;
  }
}

enum SearchStatusFilter {
  all('All Statuses'),
  releasing('Ongoing'),
  finished('Completed'),
  notYetReleased('Not Yet Released');

  final String label;
  const SearchStatusFilter(this.label);

  static SearchStatusFilter tryFromId(String? id) {
    if (id == null || id.isEmpty) return SearchStatusFilter.all;
    for (final val in values) {
      if (val.name == id || val.label == id) return val;
    }
    return SearchStatusFilter.all;
  }
}

enum SearchFormatFilter {
  all('All Formats'),
  tv('TV Series'),
  movie('Movie'),
  ova('OVA / Special'),
  manga('Manga'),
  oneShot('One Shot');

  final String label;
  const SearchFormatFilter(this.label);

  static SearchFormatFilter tryFromId(String? id) {
    if (id == null || id.isEmpty) return SearchFormatFilter.all;
    for (final val in values) {
      if (val.name == id || val.label == id) return val;
    }
    return SearchFormatFilter.all;
  }
}
