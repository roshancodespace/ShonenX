import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/core/services/anilist/auth_service.dart';
import 'package:shonenx/core/services/myanimelist/auth_service.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:commentum_client/commentum_client.dart';
import 'package:shonenx/core/commentum/commentum_client.dart';
import 'package:shonenx/core/models/auth/user.dart';

part 'auth_notifier.g.dart';

@immutable
class AuthState {
  final bool anilistLoading;
  final bool malLoading;
  final String? anilistAccessToken;
  final String? malAccessToken;
  final AuthUser? anilistUser;
  final AuthUser? malUser;
  final AuthPlatform activePlatform;

  const AuthState({
    this.anilistLoading = false,
    this.malLoading = false,
    this.anilistAccessToken,
    this.malAccessToken,
    this.anilistUser,
    this.malUser,
    this.activePlatform = AuthPlatform.anilist,
  });

  AuthState copyWith({
    bool? anilistLoading,
    bool? malLoading,
    String? anilistAccessToken,
    String? malAccessToken,
    AuthUser? anilistUser,
    AuthUser? malUser,
    AuthPlatform? activePlatform,
  }) {
    return AuthState(
      anilistLoading: anilistLoading ?? this.anilistLoading,
      malLoading: malLoading ?? this.malLoading,
      anilistAccessToken: anilistAccessToken ?? this.anilistAccessToken,
      malAccessToken: malAccessToken ?? this.malAccessToken,
      anilistUser: anilistUser ?? this.anilistUser,
      malUser: malUser ?? this.malUser,
      activePlatform: activePlatform ?? this.activePlatform,
    );
  }

  bool get isAniListAuthenticated => anilistAccessToken?.isNotEmpty == true;
  bool get isMalAuthenticated => malAccessToken?.isNotEmpty == true;

  bool isAuthenticatedFor(AuthPlatform platform) {
    return switch (platform) {
      AuthPlatform.anilist => isAniListAuthenticated,
      AuthPlatform.mal => isMalAuthenticated,
    };
  }

  AuthUser? userFor(AuthPlatform platform) {
    return switch (platform) {
      AuthPlatform.anilist => anilistUser,
      AuthPlatform.mal => malUser,
    };
  }

  bool isLoadingFor(AuthPlatform platform) {
    return switch (platform) {
      AuthPlatform.anilist => anilistLoading,
      AuthPlatform.mal => malLoading,
    };
  }
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AniListAuthService get _anilistAuthService => AniListAuthService();
  MyAnimeListAuthService get _malAuthService => MyAnimeListAuthService();

  @override
  AuthState build() {
    _init();
    return const AuthState();
  }

  Future<void> _init() async {
    await Future.wait([_loadAnilistToken(), _loadMalToken()]);
    await commentumClient.init();
    commentumClient.setActiveProvider(
      state.activePlatform == AuthPlatform.anilist
          ? CommentumProvider.anilist
          : CommentumProvider.myanimelist,
    );
  }

  AuthUser _buildAnilistUser(Map<String, dynamic> data) =>
      AuthUser.fromJson(data);

  AuthUser _buildMalUser(Map<String, dynamic> data) => AuthUser(
    id: data['id'].toString(),
    name: data['name'],
    avatarUrl: data['picture'],
  );

  Future<void> updateAnilistProfile({required String about}) async {
    try {
      await ref.read(anilistServiceProvider).updateUser(about: about);

      if (state.anilistUser != null) {
        final token = state.anilistAccessToken;
        if (token != null) {
          final userData = await ref
              .read(anilistServiceProvider)
              .getUserProfile(token);
          state = state.copyWith(anilistUser: _buildAnilistUser(userData));
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadAnilistToken() async {
    final token = await _secureStorage.read(key: 'anilist-token');
    if (token?.isNotEmpty != true) return;

    state = state.copyWith(anilistLoading: true);
    try {
      final userData = await ref
          .read(anilistServiceProvider)
          .getUserProfile(token!);
      state = state.copyWith(
        anilistAccessToken: token,
        anilistUser: _buildAnilistUser(userData),
      );
    } catch (_) {
      await _secureStorage.delete(key: 'anilist-token');
    } finally {
      state = state.copyWith(anilistLoading: false);
    }
  }

  Future<void> _loginWithAnilist() async {
    state = state.copyWith(
      anilistLoading: true,
      activePlatform: AuthPlatform.anilist,
    );
    try {
      final code = await _anilistAuthService.authenticate();
      if (code == null) return;

      final token = await _anilistAuthService.getAccessToken(code);
      if (token == null) return;

      await _secureStorage.write(key: 'anilist-token', value: token);
      final userData = await ref
          .read(anilistServiceProvider)
          .getUserProfile(token);

      // Login to Commentum
      try {
        await commentumClient.login(CommentumProvider.anilist, token);
      } catch (e) {
        debugPrint('Failed to login to Commentum with AniList: $e');
      }

      state = state.copyWith(
        anilistAccessToken: token,
        anilistUser: _buildAnilistUser(userData),
        activePlatform: AuthPlatform.anilist,
      );
    } finally {
      state = state.copyWith(anilistLoading: false);
    }
  }

  Future<void> _loadMalToken() async {
    final token = await _secureStorage.read(key: 'mal-token');
    if (token?.isNotEmpty != true) return;

    state = state.copyWith(malLoading: true);
    try {
      final profile = await _malAuthService.getUserProfile();
      if (profile != null) {
        state = state.copyWith(
          malAccessToken: token,
          malUser: _buildMalUser(profile),
        );
      }
    } catch (_) {
      await _secureStorage.delete(key: 'mal-token');
      await _secureStorage.delete(key: 'mal-refresh-token');
    } finally {
      state = state.copyWith(malLoading: false);
    }
  }

  Future<void> _loginWithMal() async {
    state = state.copyWith(malLoading: true, activePlatform: AuthPlatform.mal);
    try {
      final code = await _malAuthService.authenticate();
      if (code == null) return;

      final tokenData = await _malAuthService.getAccessToken(code);
      if (tokenData == null) return;

      final accesToken = tokenData['access_token'];

      await _secureStorage.write(key: 'mal-token', value: accesToken);
      await _secureStorage.write(
        key: 'mal-refresh-token',
        value: tokenData['refresh_token'],
      );

      final profile = await _malAuthService.getUserProfile();
      if (profile != null) {
        // Login to Commentum
        try {
          await commentumClient.login(
            CommentumProvider.myanimelist,
            accesToken,
          );
        } catch (e) {
          debugPrint('Failed to login to Commentum with MAL: $e');
        }

        state = state.copyWith(
          malAccessToken: accesToken,
          malUser: _buildMalUser(profile),
          activePlatform: AuthPlatform.mal,
        );
      }
    } finally {
      state = state.copyWith(malLoading: false);
    }
  }

  Future<void> reLoginCommentum(AuthPlatform platform) async {
    if (platform == AuthPlatform.anilist) {
      commentumClient.login(
        CommentumProvider.anilist,
        state.anilistAccessToken!,
      );
    } else if (platform == AuthPlatform.mal) {
      commentumClient.login(
        CommentumProvider.myanimelist,
        state.malAccessToken!,
      );
    }
  }

  Future<void> login(AuthPlatform platform) async {
    return switch (platform) {
      AuthPlatform.anilist => _loginWithAnilist(),
      AuthPlatform.mal => _loginWithMal(),
    };
  }

  Future<void> logout(AuthPlatform platform) async {
    switch (platform) {
      case AuthPlatform.anilist:
        await _secureStorage.delete(key: 'anilist-token');
        await commentumClient.logout(CommentumProvider.anilist);
        state = state.copyWith(anilistAccessToken: null, anilistUser: null);
        break;
      case AuthPlatform.mal:
        await _secureStorage.delete(key: 'mal-token');
        await _secureStorage.delete(key: 'mal-refresh-token');
        await commentumClient.logout(CommentumProvider.myanimelist);
        state = state.copyWith(malAccessToken: null, malUser: null);
        break;
    }

    if (state.activePlatform == platform) {
      // Logic for handling null platform if needed
    }
  }

  Future<void> refreshMalToken() async {
    final tokenData = await _malAuthService.refreshToken();
    if (tokenData != null) {
      state = state.copyWith(malAccessToken: tokenData['access_token']);
      await _secureStorage.write(
        key: 'mal-token',
        value: tokenData['access_token'],
      );
      await _secureStorage.write(
        key: 'mal-refresh-token',
        value: tokenData['refresh_token'],
      );
    }
  }

  void changePlatform(AuthPlatform platform) {
    state = state.copyWith(activePlatform: platform);
    commentumClient.setActiveProvider(
      platform == AuthPlatform.anilist
          ? CommentumProvider.anilist
          : CommentumProvider.myanimelist,
    );
  }
}
