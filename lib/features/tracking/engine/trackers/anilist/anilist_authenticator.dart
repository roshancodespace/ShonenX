import 'dart:io';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

class AnilistAuthenticator implements Authenticator {
  static final HTTP _http = HTTP();
  static final _isDesktop = Platform.isWindows || Platform.isLinux;

  String get _clientId =>
      _isDesktop ? Env.ANILIST_CLIENT_ID_LIST.last : Env.ANILIST_CLIENT_ID_LIST.first;

  String get _clientSecret => _isDesktop
      ? Env.ANILIST_CLIENT_SECRET_LIST.last
      : Env.ANILIST_CLIENT_SECRET_LIST.first;

  @override
  String get redirectUri => _isDesktop
      ? 'http://localhost:43824/success?code=1337'
      : 'shonenx://callback';

  @override
  String get callbackScheme =>
      _isDesktop ? 'http://localhost:43824' : 'shonenx';

  @override
  String get providerName => TrackerType.anilist.name;

  @override
  List<String> get apiHosts => ['graphql.anilist.co'];

  @override
  Future<String> performLogin() async {
    print(_clientId);
    print(_clientSecret);
    final url = Uri.https('anilist.co', '/api/v2/oauth/authorize', {
      'client_id': _clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
      options: FlutterWebAuth2Options(useWebview: !_isDesktop),
    );

    final code = Uri.parse(result).queryParameters['code'];

    if (code == null || code.isEmpty) {
      throw Exception('AniList Auth Error: Failed to get authorization code.');
    }

    final tokenResponse = await _http.post(
      'https://anilist.co/api/v2/oauth/token',
      body: {
        "grant_type": "authorization_code",
        "client_id": _clientId,
        "client_secret": _clientSecret,
        "redirect_uri": redirectUri,
        "code": code,
      },
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    final String? accessToken = tokenResponse.json['access_token'];

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('AniList Auth Error: Failed to exchange token.');
    }

    return accessToken;
  }
}
