import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:commentum_client/commentum_client.dart';

class CommentumTokenStorage implements CommentumStorage {
  final _storage = const FlutterSecureStorage();

  String _key(CommentumProvider p) => 'commentum_token_${p.name}';

  @override
  Future<void> saveToken(CommentumProvider provider, String token) =>
      _storage.write(key: _key(provider), value: token);

  @override
  Future<String?> getToken(CommentumProvider provider) =>
      _storage.read(key: _key(provider));

  @override
  Future<void> deleteToken(CommentumProvider provider) =>
      _storage.delete(key: _key(provider));

  @override
  Future<Map<CommentumProvider, String>> getAllTokens() async {
    final tokens = <CommentumProvider, String>{};
    for (final provider in CommentumProvider.values) {
      final token = await getToken(provider);
      if (token != null && token.isNotEmpty) {
        tokens[provider] = token;
      }
    }
    return tokens;
  }

  @override
  Future<void> clearAll() async {
    for (final provider in CommentumProvider.values) {
      await deleteToken(provider);
      await deleteProviderToken(provider);
    }
  }

  String _providerKey(CommentumProvider p) => 'commentum_provider_token_${p.name}';

  @override
  Future<void> saveProviderToken(CommentumProvider provider, String token) =>
      _storage.write(key: _providerKey(provider), value: token);

  @override
  Future<String?> getProviderToken(CommentumProvider provider) =>
      _storage.read(key: _providerKey(provider));

  @override
  Future<void> deleteProviderToken(CommentumProvider provider) =>
      _storage.delete(key: _providerKey(provider));
}
