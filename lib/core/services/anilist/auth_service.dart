import 'dart:convert';
import 'package:shonenx/core/services/oauth/base_oauth_service.dart';
import 'package:shonenx/core/utils/env_loader.dart';

class AniListAuthService extends BaseOAuthService {
  String get _clientId => isDesktop
      ? ANILIST_CLIENT_ID.split('|')[1]
      : ANILIST_CLIENT_ID.split('|')[0];
  String get _clientSecret => isDesktop
      ? ANILIST_CLIENT_SECRET.split('|')[1]
      : ANILIST_CLIENT_SECRET.split('|')[0];

  static const String _authUrl = 'https://anilist.co/api/v2/oauth/authorize';
  static const String _tokenUrl = 'https://anilist.co/api/v2/oauth/token';

  Future<String?> authenticate() async {
    final loginUrl =
        '$_authUrl?client_id=$_clientId&redirect_uri=$redirectUri&response_type=code';

    final queryParams = await performWebAuth(loginUrl);
    return queryParams?['code'];
  }

  Future<Map<String, dynamic>?> getAccessToken(String code) async {
    return await postTokenRequest(
      _tokenUrl,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "grant_type": "authorization_code",
        "client_id": _clientId,
        "client_secret": _clientSecret,
        'redirect_uri': redirectUri,
        "code": code,
      }),
    );
  }
}
