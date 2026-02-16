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
  Future<void> clearAll() async {
    throw UnimplementedError();
  }
}
