abstract class Authenticator {
  String get providerName;

  List<String> get apiHosts;

  String get redirectUri;

  String get callbackScheme;

  Future<String> performLogin();
}
