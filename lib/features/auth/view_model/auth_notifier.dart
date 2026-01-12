import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shonenx/core/anilist/services/anilist_service_provider.dart';
import 'package:shonenx/core/anilist/services/auth_service.dart';
import 'package:shonenx/core/myanimelist/services/auth_service.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/auth/model/user.dart';
import 'package:shonenx/shared/providers/auth_provider.dart';

/// ------------------- Auth State -------------------
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

/// ------------------- Auth ViewModel -------------------
class AuthViewModel extends StateNotifier<AuthState> {
  final Ref _ref;
  final AniListAuthService _anilistAuthService;
  final MyAnimeListAuthService _malAuthService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthViewModel(this._ref, this._anilistAuthService, this._malAuthService)
      : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadAnilistToken(),
      _loadMalToken(),
    ]);
  }

  /// ------------------- Helpers -------------------
  AuthUser _buildAnilistUser(Map<String, dynamic> data) =>
      AuthUser.fromJson(data);

  AuthUser _buildMalUser(Map<String, dynamic> data) => AuthUser(
        id: data['id'].toString(),
        name: data['name'],
        avatarUrl: data['picture'],
      );

  /// ------------------- Actions -------------------
  Future<void> updateAnilistProfile({required String about}) async {
    try {
      await _ref.read(anilistServiceProvider).updateUser(about: about);

      if (state.anilistUser != null) {
        final token = state.anilistAccessToken;
        if (token != null) {
          final userData =
              await _ref.read(anilistServiceProvider).getUserProfile(token);
          state = state.copyWith(anilistUser: _buildAnilistUser(userData));
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// ------------------- AniList -------------------
  Future<void> _loadAnilistToken() async {
    final token = await _secureStorage.read(key: 'anilist-token');
    if (token?.isNotEmpty != true) return;

    state = state.copyWith(anilistLoading: true);
    try {
      final userData =
          await _ref.read(anilistServiceProvider).getUserProfile(token!);
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
        anilistLoading: true, activePlatform: AuthPlatform.anilist);
    try {
      final code = await _anilistAuthService.authenticate();
      if (code == null) return;

      final token = await _anilistAuthService.getAccessToken(code);
      if (token == null) return;

      await _secureStorage.write(key: 'anilist-token', value: token);
      final userData =
          await _ref.read(anilistServiceProvider).getUserProfile(token);

      state = state.copyWith(
        anilistAccessToken: token,
        anilistUser: _buildAnilistUser(userData),
        activePlatform: AuthPlatform.anilist,
      );
    } finally {
      state = state.copyWith(anilistLoading: false);
    }
  }

  /// ------------------- MyAnimeList -------------------
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

      await _secureStorage.write(
          key: 'mal-token', value: tokenData['access_token']);
      await _secureStorage.write(
          key: 'mal-refresh-token', value: tokenData['refresh_token']);

      final profile = await _malAuthService.getUserProfile();
      if (profile != null) {
        state = state.copyWith(
          malAccessToken: tokenData['access_token'],
          malUser: _buildMalUser(profile),
          activePlatform: AuthPlatform.mal,
        );
      }
    } finally {
      state = state.copyWith(malLoading: false);
    }
  }

  /// ------------------- Public -------------------
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
        state = state.copyWith(anilistAccessToken: null, anilistUser: null);
        break;
      case AuthPlatform.mal:
        await _secureStorage.delete(key: 'mal-token');
        await _secureStorage.delete(key: 'mal-refresh-token');
        state = state.copyWith(
          malAccessToken: null,
          malUser: null,
        );
        break;
    }

    if (state.activePlatform == platform) {
      state = state.copyWith(activePlatform: null);
    }
  }

  Future<void> refreshMalToken() async {
    final tokenData = await _malAuthService.refreshToken();
    if (tokenData != null) {
      state = state.copyWith(malAccessToken: tokenData['access_token']);
      await _secureStorage.write(
          key: 'mal-token', value: tokenData['access_token']);
      await _secureStorage.write(
          key: 'mal-refresh-token', value: tokenData['refresh_token']);
    }
  }

  void changePlatform(AuthPlatform platform) {
    state = state.copyWith(activePlatform: platform);
  }
}

/// ------------------- Provider -------------------
final authProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final aService = ref.read(anilistAuthServiceProvider);
  final malService = ref.read(malAuthServiceProvider);
  return AuthViewModel(ref, aService, malService);
});
