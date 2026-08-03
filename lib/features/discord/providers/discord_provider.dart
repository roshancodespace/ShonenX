import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shonenx/core/network/secure_storage.dart';
import 'package:shonenx/features/discord/models/discord_user.dart';
import 'package:shonenx/features/discord/services/discord_api_service.dart';

class DiscordState {
  final bool isLoading;
  final String? token;
  final DiscordUser? user;
  final String? error;

  const DiscordState({
    this.isLoading = false,
    this.token,
    this.user,
    this.error,
  });

  bool get isLoggedIn => token != null && token!.isNotEmpty && user != null;

  DiscordState copyWith({
    bool? isLoading,
    String? token,
    DiscordUser? user,
    String? error,
    bool clearToken = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return DiscordState(
      isLoading: isLoading ?? this.isLoading,
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final discordProvider = NotifierProvider<DiscordNotifier, DiscordState>(
  DiscordNotifier.new,
);

class DiscordNotifier extends Notifier<DiscordState> {
  static const _tokenKey = 'discord_token';
  static const _userKey = 'discord_user_data';

  final _apiService = DiscordApiService();

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  DiscordState build() {
    _loadInitialState();
    return const DiscordState(isLoading: true);
  }

  Future<void> _loadInitialState() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final userJson = await _storage.read(key: _userKey);

      DiscordUser? user;
      if (userJson != null && userJson.isNotEmpty) {
        try {
          user = DiscordUser.fromJson(jsonDecode(userJson));
        } catch (_) {}
      }

      state = DiscordState(isLoading: false, token: token, user: user);

      if (token != null && token.isNotEmpty) {
        _refreshProfile(token);
      }
    } catch (_) {
      state = const DiscordState(isLoading: false);
    }
  }

  Future<void> _refreshProfile(String token) async {
    final fetchedUser = await _apiService.fetchUserProfile(token);
    if (fetchedUser != null) {
      await _storage.write(
        key: _userKey,
        value: jsonEncode(fetchedUser.toJson()),
      );
      if (state.token == token) {
        state = state.copyWith(user: fetchedUser);
      }
    }
  }

  Future<bool> loginWithToken(String token) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final user = await _apiService.fetchUserProfile(token);

    if (user != null) {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
      state = DiscordState(isLoading: false, token: token, user: user);
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch Discord user profile. Check token validity.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    state = const DiscordState();
  }
}
