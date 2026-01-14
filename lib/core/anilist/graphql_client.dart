import 'dart:io';
import 'package:graphql/client.dart';
import 'package:hive_ce/hive.dart';

class AnilistClient {
  static GraphQLClient? _client;
  static String? _lastToken;

  static const _baseUrl = 'https://graphql.anilist.co';

  static bool get _isTestEnvironment =>
      Platform.environment.containsKey('FLUTTER_TEST');

  static Future<void> _initHive(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    Hive.init(path);
  }

  static Future<GraphQLClient> getClient({
    String? accessToken,
    String? cachePath,
  }) async {
    if (_client != null && _lastToken == accessToken) {
      return _client!;
    }

    final httpLink = HttpLink(
      _baseUrl,
      defaultHeaders: {
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
      },
    );

    late final GraphQLCache cache;

    if (_isTestEnvironment || cachePath == null) {
      cache = GraphQLCache();
    } else {
      await _initHive(cachePath);
      final store = await HiveStore.open(path: cachePath);
      cache = GraphQLCache(store: store);
    }

    _lastToken = accessToken;
    _client = GraphQLClient(
      link: httpLink,
      cache: cache,
      queryRequestTimeout: const Duration(seconds: 15),
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.cacheAndNetwork),
        mutate: Policies(fetch: FetchPolicy.networkOnly),
      ),
    );

    return _client!;
  }

  static Future<void> clearCache() async {
    _client?.cache.store.reset();
  }
}
