import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/auth/authenticator.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';

class MalAuthenticator implements Authenticator {
  static final HTTP _http = HTTP();
  static final _isDesktop = Platform.isWindows || Platform.isLinux;
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static const String _codeVerifierKey = 'mal_code_verifier';
  static const String _authStateKey = 'mal_auth_state';

  String get _clientId =>
      _isDesktop ? Env.MAL_CLIENT_ID_LIST.last : Env.MAL_CLIENT_ID_LIST.first;

  String get _clientSecret => _isDesktop
      ? Env.MAL_CLIENT_SECRET_LIST.last
      : Env.MAL_CLIENT_SECRET_LIST.first;

  @override
  String get redirectUri => _isDesktop
      ? 'http://localhost:43824/success?code=1337'
      : 'shonenx://callback';

  @override
  String get callbackScheme =>
      _isDesktop ? 'http://localhost:43824' : 'shonenx';

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

  @override
  Future<String> performLogin() async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final state = _generateState();

      // Persist PKCE values securely
      await _secureStorage.write(key: _codeVerifierKey, value: codeVerifier);
      await _secureStorage.write(key: _authStateKey, value: state);

      final authUri = Uri.https('myanimelist.net', '/v1/oauth2/authorize', {
        'response_type': 'code',
        'client_id': _clientId,
        'redirect_uri': redirectUri,
        'code_challenge': codeVerifier, // PKCE plain method
        'code_challenge_method': 'plain',
        'state': state, // CSRF protection
      });

      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: callbackScheme,
        options: FlutterWebAuth2Options(useWebview: !_isDesktop),
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
        'client_id': _clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': codeVerifier,
        'redirect_uri': redirectUri,
      };

      if (_clientSecret.isNotEmpty) {
        bodyParams['client_secret'] = _clientSecret;
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
    } catch (e, _) {
      await _cleanupSecureStorage();
      rethrow;
    }
  }
}
