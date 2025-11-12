import 'package:graphql_flutter/graphql_flutter.dart';

class AnilistClient {
  static final String _baseUrl = 'https://graphql.anilist.co';

  static GraphQLClient getClient({String? accessToken}) {
    final HttpLink httpLink = HttpLink(
      _baseUrl,
      defaultHeaders: accessToken != null && accessToken.isNotEmpty
          ? {'Authorization': 'Bearer $accessToken'}
          : {},
    );
    return GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(),
      queryRequestTimeout: Duration(seconds: 15),
    );
  }
}