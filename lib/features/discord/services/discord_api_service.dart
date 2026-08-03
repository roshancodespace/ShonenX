import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shonenx/features/discord/models/discord_user.dart';

class DiscordApiService {
  static const String _baseUrl = 'https://discord.com/api/v9';

  Future<DiscordUser?> fetchUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/@me'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DiscordUser.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
