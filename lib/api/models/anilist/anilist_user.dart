class User {
  final String accessToken;
  final int? id;
  final String? name;
  final String? avatar;

  User({required this.accessToken, this.name = 'Guest', this.avatar, this.id});

  bool get isLoggedIn => accessToken.isNotEmpty;
}
