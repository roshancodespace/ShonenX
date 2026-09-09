import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_auth_mode.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

class SimklAuthenticator implements Authenticator {
  final TrackerCredentials? customCredentials;
  final TrackerAuthMode authMode;

  SimklAuthenticator({
    this.customCredentials,
    this.authMode = TrackerAuthMode.auto,
  });

  static final HTTP _http = HTTP();
  static final _isDesktop = Platform.isWindows || Platform.isLinux;

  static const String _desktopRedirectUri =
      'http://localhost:43824/success?code=1337';
  static const String _desktopCallbackScheme = 'http://localhost:43824';
  static const String _mobileRedirectUri = 'shonenx://callback';
  static const String _mobileCallbackScheme = 'shonenx';

  String get _mobileClientId =>
      customCredentials?.clientId.trim().isNotEmpty == true
      ? customCredentials!.clientId.trim()
      : Env.SIMKL_CLIENT_ID_LIST.first;

  String get _desktopClientId =>
      customCredentials?.clientId.trim().isNotEmpty == true
      ? customCredentials!.clientId.trim()
      : Env.SIMKL_CLIENT_ID_LIST.last;

  String get _mobileClientSecret =>
      customCredentials?.clientSecret.trim().isNotEmpty == true
      ? customCredentials!.clientSecret.trim()
      : Env.SIMKL_CLIENT_SECRET_LIST.first;

  String get _desktopClientSecret =>
      customCredentials?.clientSecret.trim().isNotEmpty == true
      ? customCredentials!.clientSecret.trim()
      : Env.SIMKL_CLIENT_SECRET_LIST.last;

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
  String get redirectUri =>
      _shouldUseWebview ? _mobileRedirectUri : _desktopRedirectUri;

  @override
  String get callbackScheme =>
      _shouldUseWebview ? _mobileCallbackScheme : _desktopCallbackScheme;

  @override
  String get providerName => TrackerType.simkl.name;

  @override
  List<String> get apiHosts => ['api.simkl.com'];

  Future<String> _loginWith({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required String callbackScheme,
    required bool useWebview,
  }) async {
    final url = Uri.https('simkl.com', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
    });

    final result = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: callbackScheme,
      options: FlutterWebAuth2Options(useWebview: useWebview),
    );

    final code = Uri.parse(result).queryParameters['code'];

    if (code == null || code.isEmpty) {
      throw Exception('Simkl Auth Error: Failed to get authorization code.');
    }

    final tokenResponse = await _http.post(
      'https://api.simkl.com/oauth/token',
      body: {
        "grant_type": "authorization_code",
        "client_id": clientId,
        "client_secret": clientSecret,
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
      throw Exception('Simkl Auth Error: Failed to exchange token.');
    }

    return accessToken;
  }

  @override
  Future<String> performLogin() async {
    // 1. Forced In-App WebView (Mobile client credentials & deep-link)
    if (authMode == TrackerAuthMode.webview) {
      return await _loginWith(
        clientId: _mobileClientId,
        clientSecret: _mobileClientSecret,
        redirectUri: _mobileRedirectUri,
        callbackScheme: _mobileCallbackScheme,
        useWebview: true,
      );
    }

    // 2. Forced External Browser (Desktop client credentials & localhost redirect)
    if (authMode == TrackerAuthMode.browser) {
      return await _loginWith(
        clientId: _desktopClientId,
        clientSecret: _desktopClientSecret,
        redirectUri: _desktopRedirectUri,
        callbackScheme: _desktopCallbackScheme,
        useWebview: false,
      );
    }

    // 3. Auto Mode: Desktop tries browser first with fallback; mobile uses WebView
    if (_isDesktop) {
      try {
        return await _loginWith(
          clientId: _desktopClientId,
          clientSecret: _desktopClientSecret,
          redirectUri: _desktopRedirectUri,
          callbackScheme: _desktopCallbackScheme,
          useWebview: false,
        );
      } catch (e) {
        if (e is PlatformException && e.code == 'CANCELED') {
          rethrow;
        }
        AppLogger.w(
          'SimklAuthenticator',
          'Desktop browser auth failed ($e). Falling back to in-app WebView...',
        );
        return await _loginWith(
          clientId: _mobileClientId,
          clientSecret: _mobileClientSecret,
          redirectUri: _mobileRedirectUri,
          callbackScheme: _mobileCallbackScheme,
          useWebview: true,
        );
      }
    }

    return await _loginWith(
      clientId: _mobileClientId,
      clientSecret: _mobileClientSecret,
      redirectUri: _mobileRedirectUri,
      callbackScheme: _mobileCallbackScheme,
      useWebview: true,
    );
  }
}
