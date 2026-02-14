enum UserRole { user, moderator, admin }

class User {
  final String id;
  final String username;
  final UserRole role;
  final String provider;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.provider,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'],
        role: UserRole.values.byName(json['role']),
        provider: json['provider'],
        avatarUrl: json['avatar_url'],
        createdAt: DateTime.parse(json['created_at']),
      );
}
