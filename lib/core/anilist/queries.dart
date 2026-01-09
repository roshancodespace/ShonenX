class AnilistQueries {
  // Common media fields to reduce redundancy (Lightweight for lists)
  static const String mediaFields = '''
    id
    idMal
    type
    format
    status
    episodes
    duration
    isAdult
    countryOfOrigin
    title {
      romaji
      english
      native
      userPreferred
    }
    coverImage {
      extraLarge
      large
      medium
      color
    }
    genres
    averageScore
    popularity
    favourites
  ''';

  // Detailed media fields (Heavy, for details screen only)
  static const String detailedMediaFields = '''
    id
    idMal
    type
    format
    status
    source
    episodes
    duration
    isAdult
    countryOfOrigin
    title {
      romaji
      english
      native
      userPreferred
    }
    coverImage {
      extraLarge
      large
      medium
      color
    }
    bannerImage
    description
    synonyms
    season
    seasonYear
    startDate {
      year
      month
      day
    }
    endDate {
      year
      month
      day
    }
    nextAiringEpisode {
      episode
      airingAt
      timeUntilAiring
    }
    genres
    tags {
      id
      name
      description
      rank
      isGeneralSpoiler
      isMediaSpoiler
      isAdult
    }
    averageScore
    meanScore
    popularity
    favourites
    rankings {
      id
      rank
      type
      format
      year
      season
      allTime
      context
    }
    studios(isMain: true) {
      edges {
        isMain
        node {
          id
          name
          siteUrl
        }
      }
    }
    relations {
      edges {
        relationType
        node {
          id
          title {
            romaji
            english
            userPreferred
          }
          coverImage {
            large
            medium
          }
           type
           format
           status
        }
      }
    }
    recommendations(sort: RATING_DESC, perPage: 10) {
      nodes {
        rating
        mediaRecommendation {
          id
          title { romaji english userPreferred }
          coverImage { large medium }
          type
          format
          status
          averageScore
        }
      }
    }
    staff(sort: RELEVANCE) {
      edges {
        role
        node {
          id
          name { full native }
          image { large medium }
        }
      }
    }
    characters(sort: ROLE, perPage: 10) {
      edges {
        role
        node {
          id
          name {
            full
            native
          }
          image {
            large
          }
        }
      }
    }
    trailer {
      id
      site
      thumbnail
    }
    siteUrl
    isFavourite
  ''';

  // Intermediate media fields (For Spotlights/Trending that need banner/description)
  static const String spotlightMediaFields = '''
    $mediaFields
    bannerImage
    description
    nextAiringEpisode {
      episode
      airingAt
      timeUntilAiring
    }
  ''';

  // Query: Search anime by title
  static String searchAnimeQuery(bool includeAdult) => '''
    query (\$search: String, \$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(search: \$search, type: ANIME, sort: POPULARITY_DESC${includeAdult ? ', isAdult: \$isAdult' : ''}) {
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
        about
        bannerImage
        avatar {
          large
        }
        statistics {
          anime {
            count
            minutesWatched
            episodesWatched
            meanScore
          }
        }
        isFollower
        isFollowing
      }
    }
  ''';

  // Mutation: Update user profile
  static const String updateUserMutation = '''
    mutation UpdateUser(\$about: String, \$titleLanguage: UserTitleLanguage, \$displayAdultContent: Boolean, \$airingNotifications: Boolean, \$profileColor: String) {
      UpdateUser(about: \$about, titleLanguage: \$titleLanguage, displayAdultContent: \$displayAdultContent, airingNotifications: \$airingNotifications, profileColor: \$profileColor) {
        id
        name
        about
        avatar {
          large
        }
        options {
          titleLanguage
          displayAdultContent
          airingNotifications
          profileColor
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
        $detailedMediaFields
      }
    }
  ''';

  // Query: Fetch trending anime
  static String trendingAnimeQuery(bool includeAdult) => '''
    query (\$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(sort: TRENDING_DESC, type: ANIME${includeAdult ? ', isAdult: \$isAdult' : ''}) {
          $spotlightMediaFields
        }
      }
    }
  ''';

  // Query: Fetch most watched anime (Popular)
  static const String mostWatchedAnimeQuery = '''
    query (\$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        media(sort: WATCHERS_DESC, type: ANIME) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch anime with most favorites
  static const String mostFavoritedAnimeQuery = '''
    query (\$page: Int, \$perPage: Int) {
      Page(page: \$page, perPage: \$perPage) {
        media(sort: FAVOURITES_DESC, type: ANIME) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch popular anime
  static String popularAnimeQuery(bool includeAdult) => '''
    query (\$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(sort: POPULARITY_DESC, type: ANIME${includeAdult ? ', isAdult: \$isAdult' : ''}) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch recently released episodes (Ongoing Anime)
  static String recentEpisodesQuery(bool includeAdult) => '''
    query (\$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(type: ANIME, status: RELEASING, sort: UPDATED_AT_DESC${includeAdult ? ', isAdult: \$isAdult' : ''}) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch seasonal anime
  static String seasonalAnimeQuery(bool includeAdult) => '''
    query (\$season: MediaSeason, \$year: Int, \$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(season: \$season, seasonYear: \$year, type: ANIME, sort: POPULARITY_DESC${includeAdult ? ', isAdult: \$isAdult' : ''}) {
          $mediaFields
        }
      }
    }
  ''';

  // Query: Fetch top-rated anime
  static String topRatedAnimeQuery(bool includeAdult) => '''
    query (\$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(sort: SCORE_DESC, type: ANIME${includeAdult ? ', isAdult: \$isAdult' : ''}) {
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
  static String recentlyUpdatedAnimeQuery(bool includeAdult) => '''
    query (\$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(sort: UPDATED_AT_DESC, type: ANIME${includeAdult ? ', isAdult: \$isAdult' : ''}) {
          $mediaFields
        }
      }
    }
  ''';
  
  // Fetch Upcoming Anime
  static String upcomingAnimeQuery(bool includeAdult) => '''
    query (\$page: Int, \$perPage: Int${includeAdult ? ', \$isAdult: Boolean' : ''}) {
      Page(page: \$page, perPage: \$perPage) {
        media(sort: START_DATE_DESC, type: ANIME, status: NOT_YET_RELEASED${includeAdult ? ', isAdult: \$isAdult' : ''}) {
          $mediaFields
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
