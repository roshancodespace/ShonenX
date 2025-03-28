import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AniListAuthService {
  static const String clientId = '22489';
  static const String clientSecret = '2IKF0qxEFlkYwpMo96UpyFJmaLgwBJZe4kZczOG6';
  static const String redirectUri = 'shonenx://callback';
  static const String authUrl = 'https://anilist.co/api/v2/oauth/authorize';
  static const String tokenUrl = 'https://anilist.co/api/v2/oauth/token';
  Future<String?> authenticate() async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url:
            '$authUrl?client_id=$clientId&redirect_uri=$redirectUri&response_type=code',
        callbackUrlScheme: 'shonenx', // Must match the Redirect URL scheme
        options: FlutterWebAuth2Options(
          silentAuth: true,
        ),
      );

      // Extract the authorization code from the redirect URL
      final code = Uri.parse(result).queryParameters['code'];
      return code;
    } catch (e) {
      debugPrint('Error during authentication: $e');
      return null;
    }
  }

  Future<String?> getAccessToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "grant_type": "authorization_code",
          "client_id": clientId,
          "client_secret": clientSecret,
          'redirect_uri': redirectUri,
          "code": code
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        debugPrint('Error fetching access token: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }
}
