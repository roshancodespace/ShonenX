class AnilistQueries {
  // Common media fields to reduce redundancy
  static const String mediaFields = '''
    id
    title {
      romaji
      english
      native
    }
    coverImage {
      large
      medium
    }
    bannerImage
    description
    episodes
    duration
    status
    format
    averageScore
    popularity
    isAdult
    rankings {
      rank
      type
      context
      season
      year
      allTime
    }
  ''';

  // Query: Search anime by title
  static const String searchAnimeQuery = '''
    query (\$search: String, \$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        media(search: \$search, type: ANIME) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Get the logged-in user's profile (Viewer)
  static const String userProfileQuery = '''
    query {
      Viewer {
        id
        name
        avatar {
          large
          medium
        }
      }
    }
  ''';

  // Query: Fetch a user's anime list by status
  static const String userAnimeListQuery = '''
    query (\$userId: Int, \$type: MediaType, \$status: MediaListStatus) {
      MediaListCollection(userId: \$userId, type: \$type, status: \$status) {
        lists {
          name
          entries {
            media {
              $mediaFields
            }
            status
            score
            progress
          }
        }
      }
    }
  ''';

  // Query: Fetch a user's favorite anime
  static const String userFavoritesQuery = '''
    query (\$userId: Int) {
      User(id: \$userId) {
        favourites {
          anime {
            nodes {
              $mediaFields
            }
          }
        }
      }
    }
  ''';

  static const String updateAnimeStatusMutation = '''
    mutation UpdateAnimeStatus(\$mediaId: Int!, \$status: MediaListStatus!) {
      SaveMediaListEntry(mediaId: \$mediaId, status: \$status) {
        $mediaFields
      }
    }
  ''';

  static const String updateAnimeMediaEntryMutation = '''
  mutation SaveMediaListEntry(
    \$mediaId: Int
    \$status: MediaListStatus
    \$score: Float
    \$progress: Int
    \$startedAt: FuzzyDateInput
    \$completedAt: FuzzyDateInput
    \$repeat: Int
    \$private: Boolean
    \$notes: String
  ) {
    SaveMediaListEntry(
      mediaId: \$mediaId
      status: \$status
      score: \$score
      progress: \$progress
      startedAt: \$startedAt
      completedAt: \$completedAt
      repeat: \$repeat
      private: \$private
      notes: \$notes
    ) {
      id
      status
      score
      progress
      repeat
      private
      notes
      startedAt {
        year
        month
        day
      }
      completedAt {
        year
        month
        day
      }
      updatedAt
    }
  }

  ''';

  /// **Query to get the anime status from the user's list**
  static const String getAnimeStatusQuery = '''
    query GetAnimeStatus(\$userId: Int, \$animeId: Int) {
      MediaList(userId: \$userId, mediaId: \$animeId) {
        status
      }
    }
  ''';

  // Query: Fetch detailed anime information by ID
  static const String animeDetailsQuery = '''
    query (\$id: Int) {
      Media(id: \$id, type: ANIME) {
        $mediaFields
        season
        seasonYear
        genres
        studios {
          nodes {
            name
          }
        }
        characters {
          nodes {
           $mediaFields
          }
        }
      }
    }
  ''';

  // Query: Fetch trending anime
  static const String trendingAnimeQuery = '''
    query {
      Page(page: 1, perPage: 15) {
        media(sort: TRENDING_DESC, type: ANIME) {
          $mediaFields
        }
      }
    }
  ''';

  static const String mostWatchedAnimeQuery = '''
  query {
    Page(page: 1, perPage: 15) {
      media(sort: WATCHERS_DESC, type: ANIME) {
        $mediaFields
      }
    }
  }
''';

// Query: Fetch anime with most favorites
  static const String mostFavoritedAnimeQuery = '''
  query {
    Page(page: 1, perPage: 15) {
      media(sort: FAVOURITES_DESC, type: ANIME) {
        $mediaFields
      }
    }
  }
''';

  // Query: Fetch popular anime
  static const String popularAnimeQuery = '''
    query {
      Page(page: 1, perPage: 15) {
        media(sort: POPULARITY_DESC, type: ANIME) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch recently released episodes (Ongoing Anime)
  static const String recentEpisodesQuery = '''
    query {
      Page(page: 1, perPage: 15) {
        media(type: ANIME, status: RELEASING, sort: UPDATED_AT_DESC) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch seasonal anime
  static const String seasonalAnimeQuery = '''
    query (\$season: MediaSeason, \$year: Int) {
      Page(page: 1, perPage: 15) {
        media(season: \$season, seasonYear: \$year, type: ANIME, sort: POPULARITY_DESC) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch top-rated anime
  static const String topRatedAnimeQuery = '''
    query {
      Page(page: 1, perPage: 15) {
        media(sort: SCORE_DESC, type: ANIME) {
          $mediaFields
        }
      }
    }
  ''';

  // Mutation: Toggle anime favorite status
  static const String toggleFavoriteQuery = '''
    mutation (\$animeId: Int!) {
      ToggleFavourite(animeId: \$animeId) {
        anime {
          nodes {
            $mediaFields
          }
        }
      }
    }
  ''';

  // Fetch Recently Updated Anime
  static const String recentlyUpdatedAnimeQuery = '''
    query {
      Page(page: 1, perPage: 10) {
        media(sort: UPDATED_AT_DESC, type: ANIME) {
          $mediaFields
        }
      }
    }
  ''';

  // Fetch Upcoming Anime
  static const String upcomingAnimeQuery = '''
    query {
      Page(page: 1, perPage: 10) {
        media(sort: START_DATE_DESC, type: ANIME, status: NOT_YET_RELEASED) {
          id
          title {
            romaji
            english
            native
          }
          coverImage {
            large
          }
          description
          episodes
          averageScore
          status
          startDate {
            year
            month
            day
          }
        }
      }
    }
  ''';

  // Save Media Progress
  static const String saveMediaProgressQuery = '''
    mutation SaveMediaProgress(\$mediaId: Int!, \$progress: Int!) {
      SaveMediaListEntry(mediaId: \$mediaId, progress: \$progress) {
        id
        status
        progress
      }
    }
  ''';

  // Query: Check if an anime is favorited
  static const String isAnimeFavoriteQuery = '''
    query (\$animeId: Int!) {
      Media(id: \$animeId) {
        isFavourite
      }
    }
  ''';

  // Query: Gets all available streaming episodes
  static const String streamingEpisodes = '''
    query (\$id: Int) {
      Media(id: \$id, type: ANIME) {
        id
        episodes
        streamingEpisodes {
          title
          thumbnail
          url
          site
        }
      }
    }

  ''';
}
