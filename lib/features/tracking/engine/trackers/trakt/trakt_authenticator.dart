import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_auth_mode.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

class TraktAuthenticator implements Authenticator {
  final TrackerCredentials? customCredentials;
  final TrackerAuthMode authMode;

  TraktAuthenticator({
    this.customCredentials,
    this.authMode = TrackerAuthMode.auto,
  });

  static final HTTP _http = HTTP();
  static final _isDesktop = Platform.isWindows || Platform.isLinux;

  static const String _traktRedirectUri =
      'https://roshancodespace.github.io/ShonenX/oauth/trakt/callback';
  static const String _desktopCallbackScheme = 'http://localhost:43824';
  static const String _mobileCallbackScheme = 'shonenx';

  String get _mobileClientId =>
      customCredentials?.clientId.trim().isNotEmpty == true
      ? customCredentials!.clientId.trim()
      : Env.TRAKT_CLIENT_ID_LIST.first;

  String get _desktopClientId =>
      customCredentials?.clientId.trim().isNotEmpty == true
      ? customCredentials!.clientId.trim()
      : Env.TRAKT_CLIENT_ID_LIST.last;

  String get _customClientSecret =>
      customCredentials?.clientSecret.trim() ?? '';

  bool get _shouldUseWebview {
    switch (authMode) {
      case TrackerAuthMode.webview:
        return true;
      case TrackerAuthMode.browser:
        return false;
      case TrackerAuthMode.auto:
        return !_isDesktop;
    }
  }

  @override
  String get redirectUri => _traktRedirectUri;

  @override
  String get callbackScheme =>
      _shouldUseWebview ? _mobileCallbackScheme : _desktopCallbackScheme;

  @override
  String get providerName => TrackerType.trakt.name;

  @override
  List<String> get apiHosts => ['api.trakt.tv'];

  String _generateCodeVerifier() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(
      64,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(ascii.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<String> _loginWith({
    required String clientId,
    required String redirectUri,
    required String callbackScheme,
    required bool useWebview,
  }) async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final statePrefix = useWebview ? 'mobile' : 'desktop';
    final state = '${statePrefix}_${_generateCodeVerifier().substring(0, 16)}';

    final url = Uri.https('trakt.tv', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
      options: FlutterWebAuth2Options(useWebview: useWebview),
    );

    final callbackUri = Uri.parse(result);
    final returnedState = callbackUri.queryParameters['state'];
    if (returnedState != null && returnedState != state) {
      throw Exception('Trakt Auth Error: State mismatch.');
    }

    final code = callbackUri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('Trakt Auth Error: Failed to get authorization code.');
    }

    final tokenBody = <String, dynamic>{
      'code': code,
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
      'code_verifier': codeVerifier,
    };
    if (_customClientSecret.isNotEmpty) {
      tokenBody['client_secret'] = _customClientSecret;
    }

    final tokenResponse = await _http.post(
      'https://api.trakt.tv/oauth/token',
      body: tokenBody,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    final String? accessToken = tokenResponse.json['access_token'];
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Trakt Auth Error: Failed to exchange token.');
    }

    return accessToken;
  }

  @override
  Future<String> performLogin() async {
    if (authMode == TrackerAuthMode.webview) {
      return _loginWith(
        clientId: _mobileClientId,
        redirectUri: _traktRedirectUri,
        callbackScheme: _mobileCallbackScheme,
        useWebview: true,
      );
    }

    if (authMode == TrackerAuthMode.browser) {
      return _loginWith(
        clientId: _desktopClientId,
        redirectUri: _traktRedirectUri,
        callbackScheme: _desktopCallbackScheme,
        useWebview: false,
      );
    }

    if (_isDesktop) {
      try {
        return await _loginWith(
          clientId: _desktopClientId,
          redirectUri: _traktRedirectUri,
          callbackScheme: _desktopCallbackScheme,
          useWebview: false,
        );
      } catch (e) {
        if (e is PlatformException && e.code == 'CANCELED') {
          rethrow;
        }
        AppLogger.w(
          'TraktAuthenticator',
          'Desktop browser auth failed ($e). Falling back to in-app WebView...',
        );
        return _loginWith(
          clientId: _mobileClientId,
          redirectUri: _traktRedirectUri,
          callbackScheme: _mobileCallbackScheme,
          useWebview: true,
        );
      }
    }

    return _loginWith(
      clientId: _mobileClientId,
      redirectUri: _traktRedirectUri,
      callbackScheme: _mobileCallbackScheme,
      useWebview: true,
    );
  }
}

