import 'package:commentum_client/commentum_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/commentum/commentum_client.dart';

final commentumAuthServiceProvider = Provider<CommentumAuthService>((ref) {
  return CommentumAuthService(ref.watch(commentumClientProvider));
});

class CommentumAuthService {
  final CommentumClient _client;

  CommentumAuthService(this._client);

  Future<void> init() async {
    await _client.init();
  }

  Future<void> signIn(
    CommentumProvider provider,
    String providerAccessToken,
  ) async {
    await _client.login(provider, providerAccessToken);
  }

  Future<void> signOut([CommentumProvider? provider]) async {
    await _client.logout(provider);
  }

  Future<void> signOutAll() async {
    await _client.logoutAll();
  }

  void switchAccount(CommentumProvider provider) {
    _client.switchProvider(provider);
  }

  List<CommentumProvider> get loggedInProviders => _client.loggedInProviders;

  CommentumProvider? get activeProvider => _client.activeProvider;

  bool get isLoggedIn => _client.isLoggedIn;

  Future<Map<CommentumProvider, User>> getLoggedInProfiles() =>
      _client.getAllLoggedInProfiles();
}
