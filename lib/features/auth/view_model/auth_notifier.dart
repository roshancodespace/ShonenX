import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/anilist/services/auth_service.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/auth/model/user.dart';
import 'package:shonenx/shared/providers/auth_provider.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? anilistAccessToken;
  final String? malAccessToken;
  final AuthUser? user;
  final AuthPlatform? authPlatform;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.anilistAccessToken,
    this.malAccessToken,
    this.user,
    this.authPlatform = AuthPlatform.anilist,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? anilistAccessToken,
    AuthUser? user,
    AuthPlatform? authPlatform,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      anilistAccessToken: anilistAccessToken ?? this.anilistAccessToken,
      user: user ?? this.user,
      authPlatform: authPlatform ?? this.authPlatform,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final Ref _ref; // Add this
  final AniListAuthService _authService;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    lOptions: LinuxOptions(),
  );

  AuthViewModel(this._ref, this._authService) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    switch (state.authPlatform) {
      case AuthPlatform.anilist:
        return await _loadAnilistToken();
      case AuthPlatform.mal:
        return await _loadMalToken();
      default:
        break;
    }
  }

  Future<void> _loadAnilistToken() async {
    final token = await secureStorage.read(key: 'anilist-token');
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(isLoading: true);
      final anilistService = _ref.read(anilistServiceProvider);
      final userData = await anilistService.getUserProfile(token);
      final user = AuthUser(
          id: userData['id'],
          name: userData['name'],
          avatarUrl: userData['avatar']['large']);
          
      state = AuthState(
        isLoggedIn: true,
        isLoading: false,
        anilistAccessToken: token,
        user: user,
      );
    }
  }

  Future<void> _loadMalToken() async {
    // TODO: Implement MAL token loading
  }
  Future<void> login() async {
    state = state.copyWith(isLoading: true);
    if (state.authPlatform == AuthPlatform.anilist) {
      await _loginWithAnilist();
    } else if (state.authPlatform == AuthPlatform.mal) {
      await _loginWithMal();
    }
  }

  Future<void> _loginWithMal() async {
    // TODO: Implement MAL login
  }

  Future<void> _loginWithAnilist() async {
    final code = await _authService.authenticate();
    if (code == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final token = await _authService.getAccessToken(code);
    if (token == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    await secureStorage.write(key: 'anilist-token', value: token);

    final anilistService = _ref.read(anilistServiceProvider);
    final userData = await anilistService.getUserProfile(token);
    final user = AuthUser(
        id: userData['id'],
        name: userData['name'],
        avatarUrl: userData['avatar']['large']);

    state = AuthState(
      isLoggedIn: true,
      isLoading: false,
      anilistAccessToken: token,
      user: user,
    );
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'anilist-token');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final service =
      ref.read(anilistAuthServiceProvider); // Assuming this is another service
  return AuthViewModel(ref, service);
});
