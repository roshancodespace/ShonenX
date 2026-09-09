import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_auth_mode.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_credentials.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

class MalAuthenticator implements Authenticator {
  final TrackerCredentials? customCredentials;
  final TrackerAuthMode authMode;

  MalAuthenticator({
    this.customCredentials,
    this.authMode = TrackerAuthMode.auto,
  });

  static final HTTP _http = HTTP();
  static final _isDesktop = Platform.isWindows || Platform.isLinux;
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static const String _codeVerifierKey = 'mal_code_verifier';
  static const String _authStateKey = 'mal_auth_state';

  static const String _desktopRedirectUri =
      'http://localhost:43824/success?code=1337';
  static const String _desktopCallbackScheme = 'http://localhost:43824';
  static const String _mobileRedirectUri = 'shonenx://callback';
  static const String _mobileCallbackScheme = 'shonenx';

  String get _mobileClientId =>
      customCredentials?.clientId.trim().isNotEmpty == true
      ? customCredentials!.clientId.trim()
      : Env.MAL_CLIENT_ID_LIST.first;

  String get _desktopClientId =>
      customCredentials?.clientId.trim().isNotEmpty == true
      ? customCredentials!.clientId.trim()
      : Env.MAL_CLIENT_ID_LIST.last;

  String get _mobileClientSecret =>
      customCredentials?.clientSecret.trim().isNotEmpty == true
      ? customCredentials!.clientSecret.trim()
      : Env.MAL_CLIENT_SECRET_LIST.first;

  String get _desktopClientSecret =>
      customCredentials?.clientSecret.trim().isNotEmpty == true
      ? customCredentials!.clientSecret.trim()
      : Env.MAL_CLIENT_SECRET_LIST.last;

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
  String get providerName => TrackerType.myanimelist.name;

  @override
  List<String> get apiHosts => ['api.myanimelist.net'];

  String _generateCodeVerifier() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(
      128,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _generateState() {
    const length = 16;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _cleanupSecureStorage() async {
    await _secureStorage.delete(key: _codeVerifierKey);
    await _secureStorage.delete(key: _authStateKey);
  }

  Future<String> _loginWith({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required String callbackScheme,
    required bool useWebview,
  }) async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final state = _generateState();

      // Persist PKCE values securely
      await _secureStorage.write(key: _codeVerifierKey, value: codeVerifier);
      await _secureStorage.write(key: _authStateKey, value: state);

      final authUri = Uri.https('myanimelist.net', '/v1/oauth2/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'code_challenge': codeVerifier, // PKCE plain method
        'code_challenge_method': 'plain',
        'state': state, // CSRF protection
      });

      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: callbackScheme,
        options: FlutterWebAuth2Options(useWebview: useWebview),
      );

      final parsedUrl = Uri.parse(result);
      final returnedState = parsedUrl.queryParameters['state'];
      final code = parsedUrl.queryParameters['code'];
      final error = parsedUrl.queryParameters['error'];
      final errorDescription = parsedUrl.queryParameters['error_description'];

      // Validate state parameter (CSRF protection)
      final storedState = await _secureStorage.read(key: _authStateKey);
      if (returnedState != storedState) {
        await _cleanupSecureStorage();
        throw Exception(
          'MyAnimeList Auth Error: State mismatch. Potential CSRF attack.',
        );
      }

      // Handle OAuth errors
      if (error != null) {
        await _cleanupSecureStorage();
        throw Exception(
          'MyAnimeList Auth Error: $error${errorDescription != null ? ' - $errorDescription' : ''}',
        );
      }

      if (code == null || code.isEmpty) {
        await _cleanupSecureStorage();
        throw Exception(
          'MyAnimeList Auth Error: Failed to get authorization code.',
        );
      }

      final bodyParams = {
        'client_id': clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
      };

      if (clientSecret.isNotEmpty) {
        bodyParams['client_secret'] = clientSecret;
      }

      final bodyString = bodyParams.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
          )
          .join('&');

      final tokenResponse = await _http.post(
        'https://myanimelist.net/v1/oauth2/token',
        body: bodyString,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      await _cleanupSecureStorage();

      final responseJson =
          tokenResponse.json ??
          jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final String? accessToken = responseJson['access_token'];

      if (accessToken == null || accessToken.isEmpty) {
        final error = responseJson['error'] ?? 'Unknown Error';
        final message =
            responseJson['message'] ??
            responseJson['error_description'] ??
            tokenResponse.body;
        throw Exception('MyAnimeList Auth Error ($error): $message');
      }
      return accessToken;
    } catch (e) {
      await _cleanupSecureStorage();
      rethrow;
    }
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
          'MalAuthenticator',
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
