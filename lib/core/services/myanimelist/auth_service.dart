import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/services/oauth/base_oauth_service.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/env_loader.dart';

class MyAnimeListAuthService extends BaseOAuthService {
  // --- Configuration ---
  String get _clientId =>
      isDesktop ? MAL_CLIENT_ID.split('|')[1] : MAL_CLIENT_ID.split('|')[0];

  String get _clientSecret => isDesktop
      ? MAL_CLIENT_SECRET.split('|')[1]
      : MAL_CLIENT_SECRET.split('|')[0];

  static const String _authUrl = 'https://myanimelist.net/v1/oauth2/authorize';
  static const String _tokenUrl = 'https://myanimelist.net/v1/oauth2/token';
  static const String _userProfileUrl =
      'https://api.myanimelist.net/v2/users/@me';

  // --- Secure Storage Keys ---
  static const String _codeVerifierKey = 'mal_code_verifier';
  static const String _authStateKey = 'mal_auth_state';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> authenticate() async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateState();

      await _secureStorage.write(key: _codeVerifierKey, value: codeVerifier);
      await _secureStorage.write(key: _authStateKey, value: state);

      final authUri = Uri.parse(_authUrl).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': _clientId,
          'redirect_uri': redirectUri,
          'code_challenge': codeChallenge,
          'state': state,
        },
      );

      final queries = await performWebAuth(authUri.toString());
      if (queries == null) return null;

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

  Future<Map<String, dynamic>?> getAccessToken(String code) async {
    try {
      final codeVerifier = await _secureStorage.read(key: _codeVerifierKey);
      if (codeVerifier == null) {
        throw Exception("Code verifier was not found in secure storage.");
      }

      AppLogger.i("Exchanging code for access token...");

      final data = await postTokenRequest(
        _tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
      );

      if (data != null) {
        AppLogger.i("Access token obtained and stored successfully.");
      }
      return data;
    } catch (e, st) {
      AppLogger.e('Error getting MAL access token', e, st);
      return null;
    }
  }

  Future<Map<String, dynamic>?> refreshToken(String token) async {
    try {
      AppLogger.i("Refreshing MAL access token...");

      final data = await postTokenRequest(
        _tokenUrl,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': token,
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
      );

      if (data != null) {
        AppLogger.i("Token refresh successful.");
      }
      return data;
    } catch (e, st) {
      AppLogger.e('Error refreshing MAL token', e, st);
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String accessToken) async {
    try {
      AppLogger.i("Fetching MAL user profile...");

      final response = await UniversalHttpClient.instance.get(
        Uri.parse(_userProfileUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        AppLogger.i("MAL user profile fetched successfully.");
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        AppLogger.w('Failed to fetch MAL user profile: ${response.body}');
        return null;
      }
    } catch (e, st) {
      AppLogger.e('Error fetching MAL user profile', e, st);
      return null;
    }
  }

  // --- PKCE Helper Methods ---

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

  String _generateCodeVerifier() {
    const length = 128;
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _generateCodeChallenge(String verifier) {
    return verifier;
  }
}
