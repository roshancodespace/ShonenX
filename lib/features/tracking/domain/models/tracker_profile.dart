class TrackerProfile {
  final String id;
  final String username;
  final String? avatarUrl;

  const TrackerProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
    };
  }

  factory TrackerProfile.fromMap(Map<String, dynamic> map) {
    return TrackerProfile(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? 'Unknown',
      avatarUrl: map['avatarUrl']?.toString(),
    );
  }
}