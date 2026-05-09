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
        avatar { large }
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

  static const String trending = '''
    query(\$page: Int = 1) {
      Page(page: \$page, perPage: 20) {
        pageInfo {
          hasNextPage
        }
        media(sort: TRENDING_DESC, type: ANIME, isAdult: false) {
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

  static const String metadataSearch = '''
    query(
      \$search: String,
      \$page: Int = 1,
      \$type: MediaType!,
      \$isAdult: Boolean = false,
      \$sort: [MediaSort] = [SEARCH_MATCH],
    ) {
      Page(page: \$page, perPage: 20) {
        pageInfo {
          hasNextPage
        }
        media(
          search: \$search
          type: \$type
          isAdult: \$isAdult
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
}
