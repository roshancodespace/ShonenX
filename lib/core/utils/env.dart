// ignore_for_file: non_constant_identifier_names

String COMMENTUM_API_URL = String.fromEnvironment('COMMENTUM_API_URL');
List<String> ANILIST_CLIENT_ID = String.fromEnvironment(
  'ANILIST_CLIENT_ID',
).split('|');
List<String> ANILIST_CLIENT_SECRET = String.fromEnvironment(
  'ANILIST_CLIENT_SECRET',
).split('|');
List<String> MAL_CLIENT_ID = String.fromEnvironment('MAL_CLIENT_ID').split('|');
List<String> MAL_CLIENT_SECRET = String.fromEnvironment(
  'MAL_CLIENT_SECRET',
).split('|');
