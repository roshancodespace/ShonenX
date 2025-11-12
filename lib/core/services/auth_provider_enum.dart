enum AuthPlatform { anilist, mal }

extension AuthPlatformName on AuthPlatform {
  String get name {
    switch (this) {
      case AuthPlatform.anilist:
        return 'AniList';
      case AuthPlatform.mal:
        return 'MyAnimeList';
    }
  }
}
