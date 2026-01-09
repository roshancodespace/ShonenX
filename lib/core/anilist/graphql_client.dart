import 'dart:io';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:path_provider/path_provider.dart';

class AnilistClient {
  static GraphQLClient? _client;
  static String? _lastToken;

  static const _baseUrl = 'https://graphql.anilist.co';

  static Future<GraphQLClient> getClient({String? accessToken}) async {
    if (_client != null && _lastToken == accessToken) {
      return _client!;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath =
        '${appDocDir.path}${Platform.pathSeparator}ShonenX${Platform.pathSeparator}appdata';

    final httpLink = HttpLink(_baseUrl);

    final authLink = AuthLink(
      getToken: () async =>
          (accessToken == null || accessToken.isEmpty)
              ? null
              : 'Bearer $accessToken',
    );

    final link = authLink.concat(httpLink);

    final store = await HiveStore.open(path: hivePath);

    _lastToken = accessToken;
    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: store),
      queryRequestTimeout: const Duration(seconds: 15),
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.cacheFirst),
        mutate: Policies(fetch: FetchPolicy.networkOnly),
      ),
    );

    return _client!;
  }

  static void clearCache() {
    _client?.cache.store.reset();
  }
}
