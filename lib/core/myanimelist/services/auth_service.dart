import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/universal_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/env_loader.dart';

class MyAnimeListAuthService {
  // --- Configuration ---
  static String get clientId => MAL_CLIENT_ID;
  static String get clientSecret => MAL_CLIENT_SECRET;

  static const String _redirectUri = 'shonenx://callback';
  static const String _callbackScheme = 'shonenx';
  static const String _authUrl = 'https://myanimelist.net/v1/oauth2/authorize';
  static const String _tokenUrl = 'https://myanimelist.net/v1/oauth2/token';
  static const String _userProfileUrl =
      'https://api.myanimelist.net/v2/users/@me';

  // --- Secure Storage Keys ---
  static const String _codeVerifierKey = 'mal_code_verifier';
  static const String _authStateKey = 'mal_auth_state';
  static const String _accessTokenKey = 'mal-token';
  static const String _refreshTokenKey = 'mal-refresh-token';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Step 1: Authenticate user and get authorization code.
  Future<String?> authenticate() async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      // Store the verifier and state for use in the next step and for validation
      await _secureStorage.write(key: _codeVerifierKey, value: codeVerifier);
      await _secureStorage.write(key: _authStateKey, value: state);

      final authUri = Uri.parse(_authUrl).replace(queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': _redirectUri,
        'code_challenge': codeChallenge,
        'state': state,
      });

      AppLogger.i("Opening MAL auth URL: $authUri");

      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: _callbackScheme,
      );

      final queries = Uri.parse(result).queryParameters;
      final returnedState = queries['state'];
      final storedState = await _secureStorage.read(key: _authStateKey);
      final code = queries['code'];

      // Validate state to prevent CSRF attacks
      if (returnedState != storedState) {
        throw Exception("State mismatch! Potential CSRF attack.");
      }
      if (code == null) {
        throw Exception("Authorization code not received from MAL.");
      }

      AppLogger.i("MAL authorization successful, code retrieved.");
      return code;
    } catch (e, st) {
      AppLogger.e('Error during MAL authentication', e, st);
      return null;
    }
  }

  /// Step 2: Exchange authorization code for access & refresh tokens.
  Future<Map<String, dynamic>?> getAccessToken(String code) async {
    try {
      final codeVerifier = await _secureStorage.read(key: _codeVerifierKey);
      if (codeVerifier == null) {
        throw Exception("Code verifier was not found in secure storage.");
      }

      AppLogger.i("Exchanging code for access token...");

      final response = await UniversalHttpClient.instance.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': _redirectUri,
          'code_verifier': await _secureStorage.read(key: _codeVerifierKey)
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        AppLogger.i("Access token obtained and stored successfully.");
        return data;
      } else {
        AppLogger.w('Failed to fetch MAL access token: ${response.body}');
        return null;
      }
    } catch (e, st) {
      AppLogger.e('Error getting MAL access token', e, st);
      return null;
    }
  }

  /// Refresh access token (compatible with the restored storage logic).
  Future<Map<String, dynamic>?> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) throw Exception("No refresh token found.");

      AppLogger.i("Refreshing MAL access token...");

      final response = await UniversalHttpClient.instance.post(
        Uri.parse(_tokenUrl),
        headers: {'Content-Type': 'application/x-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _secureStorage.write(
            key: _accessTokenKey, value: data['access_token']);
        await _secureStorage.write(
            key: _refreshTokenKey, value: data['refresh_token']);

        AppLogger.i("Token refresh successful.");
        return data;
      } else {
        AppLogger.w('Failed to refresh MAL token: ${response.body}');
        return null;
      }
    } catch (e, st) {
      AppLogger.e('Error refreshing MAL token', e, st);
      return null;
    }
  }

  /// Fetch authenticated user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final accessToken = await _secureStorage.read(key: _accessTokenKey);
      if (accessToken == null) throw Exception("No access token found.");

      AppLogger.i("Fetching MAL user profile...");

      final response = await UniversalHttpClient.instance.get(
        Uri.parse(_userProfileUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        AppLogger.i("MAL user profile fetched successfully.");
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        AppLogger.w("Access token expired, refreshing...");
        await refreshToken();
        return getUserProfile(); // Retry
      } else {
        AppLogger.w('Failed to fetch MAL user profile: ${response.body}');
        return null;
      }
    } catch (e, st) {
      AppLogger.e('Error fetching MAL user profile', e, st);
      return null;
    }
  }

  // --- PKCE Helper Methods (from reference code) ---

  String _generateState() {
    const length = 16;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateCodeVerifier() {
    const length = 128; // 43–128 characters allowed
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateCodeChallenge(String verifier) {
    // For MAL, just return the verifier (plain method)
    return verifier;
  }
}
