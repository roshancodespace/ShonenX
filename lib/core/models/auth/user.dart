class AuthUser {
  final String id;
  final String name;

  // Visual
  final String? avatarUrl;
  final String? avatarMediumUrl;
  final String? bannerImage;
  final String? profileColor;

  // Bio
  final String? about;

  // Preferences
  final String? titleLanguage;
  final bool? displayAdultContent;
  final bool? airingNotifications;

  // Anime stats
  final int? animeCount;
  final int? minutesWatched;
  final int? episodesWatched;
  final double? meanScore;
  final double? standardDeviation;

  const AuthUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.avatarMediumUrl,
    this.bannerImage,
    this.profileColor,
    this.about,
    this.titleLanguage,
    this.displayAdultContent,
    this.airingNotifications,
    this.animeCount,
    this.minutesWatched,
    this.episodesWatched,
    this.meanScore,
    this.standardDeviation,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar'];
    final options = json['options'];
    final animeStats = json['statistics']?['anime'];

    return AuthUser(
      id: json['id'].toString(),
      name: json['name'],
      avatarUrl: avatar?['large'],
      avatarMediumUrl: avatar?['medium'],
      bannerImage: json['bannerImage'],
      profileColor: options?['profileColor'],
      about: json['about'],
      titleLanguage: options?['titleLanguage'],
      displayAdultContent: options?['displayAdultContent'],
      airingNotifications: options?['airingNotifications'],
      animeCount: animeStats?['count'],
      minutesWatched: animeStats?['minutesWatched'],
      episodesWatched: animeStats?['episodesWatched'],
      meanScore: animeStats?['meanScore']?.toDouble(),
      standardDeviation: animeStats?['standardDeviation']?.toDouble(),
    );
  }
}
