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
    query (\$userId: Int, \$type: MediaType, \$status: MediaListStatus, \$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
          perPage
        }
        mediaList(userId: \$userId, type: \$type, status: \$status) {
          id
          status
          score
          progress
          media {
            $mediaFields
          }
        }
      }
    }
  ''';

  // Query: Fetch a user's entire anime list
  static const String userFullAnimeListQuery = '''
    query (\$userName: String, \$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        pageInfo {
          total
          currentPage
          lastPage
          hasNextPage
          perPage
        }
        mediaList(userName: \$userName, type: ANIME) {
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
          $mediaFields
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

  // Query: Update a MediaListEntry for a specific anime (requires userId or auth token)
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

    // Query: Fetch a MediaListEntry for a specific anime (requires userId or auth token)
  static const String mediaListEntryByAnimeIdQuery = '''
    query (\$userId: Int, \$animeId: Int) {
      MediaList(userId: \$userId, mediaId: \$animeId) {
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
        media {
          $mediaFields
        }
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

  // Query: Fetch most watched anime
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

}
