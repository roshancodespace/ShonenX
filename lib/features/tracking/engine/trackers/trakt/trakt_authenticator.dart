import 'dart:io';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

class TraktAuthenticator implements Authenticator {
  final TrackerCredentials? customCredentials;

  TraktAuthenticator({this.customCredentials});

  static final HTTP _http = HTTP();
  static final _isDesktop = Platform.isWindows || Platform.isLinux;

  // Standard public client credentials for ShonenX (or user provided custom)
  String get _clientId =>
      customCredentials?.clientId ??
      '030ef1d48c8b417c8052aa8bc0d9eb4f40f0c0587d1591880ca0eb65851725cf';

  String get _clientSecret =>
      customCredentials?.clientSecret ??
      '4cefa94b7e9e62cf03b9b0098f98bc5bb10c14b3017a493a778cba22cf551ee6';

  @override
  String get redirectUri => _isDesktop
      ? 'http://localhost:43824/success?code=1337'
      : 'shonenx://callback';

  @override
  String get callbackScheme =>
      _isDesktop ? 'http://localhost:43824' : 'shonenx';

  @override
  String get providerName => TrackerType.trakt.name;

  @override
  List<String> get apiHosts => ['api.trakt.tv'];

  @override
  Future<String> performLogin() async {
    final url = Uri.https('trakt.tv', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': redirectUri,
    });

    final result = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
      options: FlutterWebAuth2Options(useWebview: !_isDesktop),
    );

    final code = Uri.parse(result).queryParameters['code'];

    if (code == null || code.isEmpty) {
      throw Exception('Trakt Auth Error: Failed to get authorization code.');
    }

    final tokenResponse = await _http.post(
      'https://api.trakt.tv/oauth/token',
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
      throw Exception('Trakt Auth Error: Failed to exchange token.');
    }

    return accessToken;
  }
}
