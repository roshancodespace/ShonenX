import 'dart:convert';
import 'dart:io';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';

abstract class BaseOAuthService {
  bool get isDesktop => Platform.isWindows || Platform.isLinux;

  String get redirectUri => isDesktop
      ? 'http://localhost:43824/success?code=1337'
      : 'shonenx://callback';

  String get callbackUrlScheme =>
      isDesktop ? 'http://localhost:43824' : 'shonenx';

  /// Wraps [FlutterWebAuth2.authenticate] using common parameters and options.
  /// Returns the query parameters of the callback URL.
  Future<Map<String, String>?> performWebAuth(String url) async {
    try {
      AppLogger.i('Opening auth URL: $url');
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: callbackUrlScheme,
        options: FlutterWebAuth2Options(useWebview: !isDesktop),
      );
      AppLogger.i('Authentication callback received.');
      return Uri.parse(result).queryParameters;
    } catch (e, st) {
      AppLogger.e('Error during web authentication', e, st);
      return null;
    }
  }

  /// Sends a POST request to exchange a code or refresh a token.
  /// Handles the response checking and JSON decoding.
  Future<Map<String, dynamic>?> postTokenRequest(
    String url, {
    required Map<String, String> headers,
    required Object body,
  }) async {
    try {
      final response = await UniversalHttpClient.instance.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        AppLogger.w(
          'Token request failed: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e, st) {
      AppLogger.e('Error performing token request', e, st);
      return null;
    }
  }
}
