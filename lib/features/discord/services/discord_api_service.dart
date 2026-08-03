import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discord/models/discord_user.dart';

class DiscordApiService {
  static const String _baseUrl = 'https://discord.com/api/v9';
  final _log = AppLogger.scope(DiscordApiService);

  Future<DiscordUser?> fetchUserProfile(String token) async {
    _log.i('Fetching Discord user profile...');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/@me'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final user = DiscordUser.fromJson(data);
        _log.s('Discord user profile fetched: ${user.username}');
        return user;
      }
      _log.warning(
        'Failed to fetch Discord user profile: HTTP ${response.statusCode}',
      );
      return null;
    } catch (e, s) {
      _log.e('Error fetching Discord user profile', e, s);
      return null;
    }
  }
}
