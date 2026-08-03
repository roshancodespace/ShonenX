class DiscordUser {
  final String id;
  final String username;
  final String? globalName;
  final String? avatar;
  final String? banner;
  final int? accentColor;

  const DiscordUser({
    required this.id,
    required this.username,
    this.globalName,
    this.avatar,
    this.banner,
    this.accentColor,
  });

  String get displayName =>
      globalName != null && globalName!.isNotEmpty ? globalName! : username;

  String? get avatarUrl {
    if (avatar != null && avatar!.isNotEmpty) {
      final ext = avatar!.startsWith('a_') ? 'gif' : 'png';
      return 'https://cdn.discordapp.com/avatars/$id/$avatar.$ext?size=256';
    }
    final defaultIndex = _defaultAvatarIndex;
    return 'https://cdn.discordapp.com/embed/avatars/$defaultIndex.png';
  }

  String? get bannerUrl {
    if (banner != null && banner!.isNotEmpty) {
      final ext = banner!.startsWith('a_') ? 'gif' : 'png';
      return 'https://cdn.discordapp.com/banners/$id/$banner.$ext?size=512';
    }
    return null;
  }

  int get _defaultAvatarIndex {
    try {
      final idNum = BigInt.parse(id);
      return ((idNum >> 22) % BigInt.from(6)).toInt();
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'global_name': globalName,
      'avatar': avatar,
      'banner': banner,
      'accent_color': accentColor,
    };
  }

  factory DiscordUser.fromJson(Map<String, dynamic> json) {
    return DiscordUser(
      id: json['id'] as String,
      username: json['username'] as String,
      globalName: json['global_name'] as String?,
      avatar: json['avatar'] as String?,
      banner: json['banner'] as String?,
      accentColor: json['accent_color'] as int?,
    );
  }
}
