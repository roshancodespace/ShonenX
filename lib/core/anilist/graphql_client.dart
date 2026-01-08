import 'package:graphql_flutter/graphql_flutter.dart';

class AnilistClient {
  static final String _baseUrl = 'https://graphql.anilist.co';

  static GraphQLClient getClient({String? accessToken}) {
    final HttpLink httpLink = HttpLink(_baseUrl);
    final AuthLink authLink = AuthLink(getToken: () async {
      if (accessToken == null || accessToken.isEmpty) return null;
      return 'Bearer $accessToken';
    });
    final Link link = authLink.concat(httpLink);
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
      queryRequestTimeout: Duration(seconds: 15),
      defaultPolicies: DefaultPolicies(
        query: Policies(fetch: FetchPolicy.cacheFirst),
        mutate: Policies(fetch: FetchPolicy.networkOnly),
      ),
    );
  }
}
