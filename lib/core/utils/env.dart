// ignore_for_file: non_constant_identifier_names, constant_identifier_names

class Env {
  static const RELEASE_REPO = String.fromEnvironment(
    'RELEASE_REPO',
    defaultValue: 'Zcross091/KuroX',
  );

  static const COMMENTUM_API_URL = String.fromEnvironment('COMMENTUM_API_URL');

  // Bundled default public client IDs (verified working for OAuth and metadata)
  static const _defaultAnilistId = '51784|51784';
  static const _rawAnilistId = String.fromEnvironment(
    'ANILIST_CLIENT_ID',
    defaultValue: _defaultAnilistId,
  );
  static String get ANILIST_CLIENT_ID =>
      _rawAnilistId.trim().isEmpty ? _defaultAnilistId : _rawAnilistId;

  static const _defaultAnilistSecret =
      'RilknAXcBMEeNvHW6Pmiw11ljCB4ml2zMV4POKRG|RilknAXcBMEeNvHW6Pmiw11ljCB4ml2zMV4POKRG';
  static const _rawAnilistSecret = String.fromEnvironment(
    'ANILIST_CLIENT_SECRET',
    defaultValue: _defaultAnilistSecret,
  );
  static String get ANILIST_CLIENT_SECRET =>
      _rawAnilistSecret.trim().isEmpty
          ? _defaultAnilistSecret
          : _rawAnilistSecret;

  static const _defaultMalId =
      '281bee8ed86f5e410705a2243c359761|281bee8ed86f5e410705a2243c359761';
  static const _rawMalId = String.fromEnvironment(
    'MAL_CLIENT_ID',
    defaultValue: _defaultMalId,
  );
  static String get MAL_CLIENT_ID =>
      _rawMalId.trim().isEmpty ? _defaultMalId : _rawMalId;

  static const MAL_CLIENT_SECRET = String.fromEnvironment('MAL_CLIENT_SECRET');

  static const SIMKL_CLIENT_ID = String.fromEnvironment('SIMKL_CLIENT_ID');

  static const SIMKL_CLIENT_SECRET = String.fromEnvironment(
    'SIMKL_CLIENT_SECRET',
  );

  // helpers
  static List<String> get ANILIST_CLIENT_ID_LIST =>
      ANILIST_CLIENT_ID.split('|');

  static List<String> get ANILIST_CLIENT_SECRET_LIST =>
      ANILIST_CLIENT_SECRET.split('|');

  static List<String> get MAL_CLIENT_ID_LIST => MAL_CLIENT_ID.split('|');

  static List<String> get MAL_CLIENT_SECRET_LIST =>
      MAL_CLIENT_SECRET.split('|');

  static List<String> get SIMKL_CLIENT_ID_LIST => SIMKL_CLIENT_ID.split('|');

  static List<String> get SIMKL_CLIENT_SECRET_LIST =>
      SIMKL_CLIENT_SECRET.split('|');
}
