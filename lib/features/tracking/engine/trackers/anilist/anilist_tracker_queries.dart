import 'package:shonenx/shared/providers/content_prefs_provider.dart';

class AnilistTrackerQueries {
  static const String search = '''
    query(\$search: String, \$type: MediaType) {
      Page(page: 1, perPage: 15) {
        media(search: \$search, type: \$type) {
          id
          title {
            english
            romaji
          }
          format
          coverImage {
            large
          }
        }
      }
    }
  ''';

  static const String updateEntry = '''
    mutation(\$mediaId: Int, \$status: MediaListStatus, \$progress: Int, \$scoreRaw: Int) {
      SaveMediaListEntry(
        mediaId: \$mediaId,
        status: \$status,
        progress: \$progress,
        scoreRaw: \$scoreRaw
      ) {
        id
      }
    }
  ''';

  static const String viewerProfile = '''
    query {
      Viewer {
        id
        name
        about
        siteUrl
        bannerImage
        avatar { large }
        statistics {
          anime {
            count
            episodesWatched
            minutesWatched
            meanScore
            statuses { status count }
          }
          manga {
            count
            chaptersRead
            meanScore
            statuses { status count }
          }
        }
        favourites {
          anime(page: 1, perPage: 10) {
            nodes { coverImage { large } }
          }
        }
      }
    }
  ''';

  static const String mediaListItem = '''
    query(\$userId: Int, \$mediaId: Int) {
      MediaList(userId: \$userId, mediaId: \$mediaId) {
        id
        status
        progress
        score
      }
    }
  ''';

  static const String userLibrary = '''
    query(
      \$userId: Int,
      \$status: MediaListStatus,
      \$page: Int,
      \$type: MediaType,
    ) {
      Page(page: \$page, perPage: 50) {
        pageInfo {
          hasNextPage
        }
        mediaList(
          userId: \$userId,
          status: \$status,
          type: \$type,
          sort: [STARTED_ON_DESC],
        ) {
          media {
            id
            type
            format
            title { english romaji native }
            coverImage { large }
            status
            episodes
          }
        }
      }
    }
  ''';

  static const String deleteEntry = '''
    mutation (\$id: Int) {
      DeleteMediaListEntry(id: \$id) {
        deleted
    }
    }
  ''';

  static String trending(AdultContentMode mode) {
    String adultFilter = '';
    if (mode == AdultContentMode.safe) adultFilter = ', isAdult: false';
    if (mode == AdultContentMode.adultOnly) adultFilter = ', isAdult: true';

    return '''
    query(\$page: Int = 1, \$type: MediaType) {
      Page(page: \$page, perPage: 20) {
        pageInfo {
          hasNextPage
        }
        media(sort: TRENDING_DESC, type: \$type $adultFilter) {
          id
          nextAiringEpisode {
            episode
            airingAt
          }
          title {
            romaji
            english
            native
          }
          format
          coverImage {
            large
          }
          bannerImage
          description(asHtml: false)
          status
          averageScore
          episodes
        }
      }
    }
  ''';
  }

  static String metadataSearch(AdultContentMode mode) {
    String adultFilter = '';
    if (mode == AdultContentMode.safe) adultFilter = 'isAdult: false';
    if (mode == AdultContentMode.adultOnly) adultFilter = 'isAdult: true';

    return '''
    query(
      \$search: String,
      \$page: Int = 1,
      \$type: MediaType!,
      \$genre_in: [String],
      \$tag_in: [String],
      \$sort: [MediaSort] = [SEARCH_MATCH],
    ) {
      Page(page: \$page, perPage: 20) {
        pageInfo {
          hasNextPage
        }
        media(
          search: \$search
          type: \$type
          genre_in: \$genre_in
          tag_in: \$tag_in
          $adultFilter
          sort: \$sort
        ) {
          id
          idMal
          title {
            romaji
            english
          }
          format
          coverImage {
            large
          }
          nextAiringEpisode {
            episode
            airingAt
          }
          bannerImage
          description(asHtml: false)
          status
          averageScore
          episodes
        }
      }
    }
  ''';
  }

  static const String details = '''
    query(\$id: Int!, \$type: MediaType!) {
      Media(id: \$id, type: \$type) {
        id
        idMal
        type
        title {
          romaji
          english
          native
        }
        format
        coverImage {
          large
        }
        nextAiringEpisode {
          episode
          airingAt
        }
        bannerImage
        description(asHtml: false)
        status
        averageScore
        episodes
        genres
        tags {
          id
          name
          category
        }

        relations {
          edges {
            relationType(version: 2)
            node {
              id
              type
              format
              title {
                romaji
                english
                native
              }
              coverImage {
                large
              }
              bannerImage
              status
              averageScore
              episodes
            }
          }
        }

        recommendations(sort: RATING_DESC, perPage: 15) {
          nodes {
            mediaRecommendation {
              id
              type
              format
              title {
                romaji
                english
                native
              }
              coverImage {
                large
              }
              bannerImage
              status
              averageScore
              episodes
            }
          }
        }

        characters(role: MAIN, sort: [ROLE, RELEVANCE]) {
          nodes {
            name {
              full
            }
            image {
              large
            }
          }
        }
      }
    }
  ''';

  static String get genres => '''
    query {
      GenreCollection
    }
  ''';

  static String get tags => '''
    query {
      MediaTagCollection {
        name
      }
    }
  ''';
}
