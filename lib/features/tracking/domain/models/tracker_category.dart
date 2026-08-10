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

  static TrackerCategory? tryFromId(String? id) {
    if (id == null || id.isEmpty) return null;
    final cleanId = id.trim().toLowerCase();
    for (final category in values) {
      if (category.id.toLowerCase() == cleanId ||
          category.name.toLowerCase() == cleanId ||
          category.label.toLowerCase() == cleanId) {
        return category;
      }
    }
    if (cleanId.contains('trending')) return TrackerCategory.trending;
    if (cleanId.contains('popular') && cleanId.contains('season')) {
      return TrackerCategory.popularThisSeason;
    }
    if (cleanId.contains('popular')) return TrackerCategory.popular;
    if (cleanId.contains('upcoming')) return TrackerCategory.upcoming;
    if (cleanId.contains('top rated') ||
        cleanId.contains('top_rated') ||
        cleanId.contains('toprated')) {
      return TrackerCategory.topRated;
    }
    if (cleanId.contains('updated')) return TrackerCategory.recentlyUpdated;
    return null;
  }
}
