import 'dart:io';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';

class AnilistAuthenticator implements Authenticator {
  final TrackerCredentials? customCredentials;

  AnilistAuthenticator({this.customCredentials});

  static final HTTP _http = HTTP();
  static final _isDesktop = Platform.isWindows || Platform.isLinux;

  String get _clientId =>
      customCredentials?.clientId ??
      (_isDesktop
          ? Env.ANILIST_CLIENT_ID_LIST.last
          : Env.ANILIST_CLIENT_ID_LIST.first);

  String get _clientSecret =>
      customCredentials?.clientSecret ??
      (_isDesktop
          ? Env.ANILIST_CLIENT_SECRET_LIST.last
          : Env.ANILIST_CLIENT_SECRET_LIST.first);

  bool get _isCustom =>
      customCredentials != null && customCredentials!.clientId.isNotEmpty;

  bool get _hasSecret => _clientSecret.trim().isNotEmpty;

  @override
  String get redirectUri => 'anilistlogin://callback';

  @override
  String get callbackScheme => 'anilistlogin';

  @override
  String get providerName => TrackerType.anilist.name;

  @override
  List<String> get apiHosts => ['graphql.anilist.co'];

  @override
  Future<String> performLogin() async {
    // For default/bundled client (public client ID 51784), always use the standard
    // Implicit Grant flow (response_type=token). Client secrets must not be used or
    // required in public mobile/desktop apps, avoiding invalid_client errors.
    final useImplicitGrant = !_isCustom || !_hasSecret;

    final authParams = <String, String>{
      'client_id': _clientId,
      'response_type': useImplicitGrant ? 'token' : 'code',
      'redirect_uri': redirectUri,
    };

    final url = Uri.https('anilist.co', '/api/v2/oauth/authorize', authParams);

    final result = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
      options: const FlutterWebAuth2Options(
        preferEphemeral: false,
        useWebview: true,
      ),
    );

    final sanitizedResult = result.contains('://')
        ? result
        : result.replaceFirst(':', '://');
    final uri = Uri.parse(sanitizedResult);

    final fragmentParams = uri.fragment.isNotEmpty
        ? Uri.splitQueryString(uri.fragment)
        : const <String, String>{};

    // Check for error in redirect
    final error = uri.queryParameters['error'] ?? fragmentParams['error'];
    final errorDescription = uri.queryParameters['error_description'] ??
        fragmentParams['error_description'];
    if (error != null && error.isNotEmpty) {
      throw Exception(
        'AniList Auth Error: $error${errorDescription != null ? ' ($errorDescription)' : ''}',
      );
    }

    // Implicit grant returns '#access_token=...' in URL fragment
    String? accessToken;
    if (uri.fragment.isNotEmpty) {
      accessToken = fragmentParams['access_token'];
    }
    accessToken ??= uri.queryParameters['access_token'];

    if (accessToken != null && accessToken.isNotEmpty) {
      return accessToken;
    }

    if (useImplicitGrant) {
      throw Exception('AniList Auth Error: Failed to obtain access token.');
    }

    // If authorization code grant flow with secret
    final code = uri.queryParameters['code'] ?? fragmentParams['code'];
    if (code == null || code.isEmpty) {
      throw Exception('AniList Auth Error: Failed to obtain access token or code.');
    }

    final tokenBody = <String, dynamic>{
      "grant_type": "authorization_code",
      "client_id": _clientId,
      "code": code,
      "redirect_uri": redirectUri,
    };
    if (_clientSecret.isNotEmpty) {
      tokenBody["client_secret"] = _clientSecret;
    }

    final tokenResponse = await _http.post(
      'https://anilist.co/api/v2/oauth/token',
      body: tokenBody,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    final String? exchangedToken = tokenResponse.json?['access_token'];

    if (exchangedToken == null || exchangedToken.isEmpty) {
      final err = tokenResponse.json?['message'] ??
          tokenResponse.json?['error'] ??
          tokenResponse.body;
      throw Exception('AniList Auth Error: Failed to exchange token ($err).');
    }

    return exchangedToken;
  }
}
