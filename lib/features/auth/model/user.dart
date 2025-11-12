class AuthUser {
  final String id;
  final String name;
  final String? avatarUrl;

  const AuthUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar']['large'],
    );
  }
}
