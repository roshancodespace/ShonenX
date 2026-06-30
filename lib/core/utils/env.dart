// ignore_for_file: non_constant_identifier_names, constant_identifier_names

class Env {
  static const RELEASE_REPO = String.fromEnvironment('RELEASE_REPO');

  static const COMMENTUM_API_URL = String.fromEnvironment('COMMENTUM_API_URL');

  static const ANILIST_CLIENT_ID = String.fromEnvironment('ANILIST_CLIENT_ID');

  static const ANILIST_CLIENT_SECRET = String.fromEnvironment(
    'ANILIST_CLIENT_SECRET',
  );

  static const MAL_CLIENT_ID = String.fromEnvironment('MAL_CLIENT_ID');

  static const MAL_CLIENT_SECRET = String.fromEnvironment('MAL_CLIENT_SECRET');

  // helpers
  static List<String> get ANILIST_CLIENT_ID_LIST =>
      ANILIST_CLIENT_ID.split('|');

  static List<String> get ANILIST_CLIENT_SECRET_LIST =>
      ANILIST_CLIENT_SECRET.split('|');

  static List<String> get MAL_CLIENT_ID_LIST => MAL_CLIENT_ID.split('|');

  static List<String> get MAL_CLIENT_SECRET_LIST =>
      MAL_CLIENT_SECRET.split('|');
}
