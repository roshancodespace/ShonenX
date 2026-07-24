/// Represents a queryable discovery category/section provided by a tracking service.
enum TrackerCategory {
  trending('Trending', 'Trending Now'),
  popular('Popular', 'All-Time Popular'),
  popularThisSeason('Popular This Season', 'Popular This Season'),
  upcoming('Upcoming', 'Upcoming Next Season'),
  topRated('Top Rated', 'Top Rated All-Time'),
  recentlyUpdated('Recently Updated', 'Recently Updated');

  final String id;
  final String label;

  const TrackerCategory(this.id, this.label);

  static TrackerCategory? tryFromId(String id) {
    for (final category in values) {
      if (category.id == id || category.name == id) return category;
    }
    return null;
  }
}
