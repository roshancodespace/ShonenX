class RemoteConfig {
  final bool downloadsEnabled;
  final bool applicationEnabled;
  final String minimumVersion;
  final AnnouncementsConfig announcements;
  final Map<String, SourceConfig> sources;

  RemoteConfig({
    this.downloadsEnabled = true,
    this.applicationEnabled = true,
    this.minimumVersion = '',
    required this.announcements,
    this.sources = const {},
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    final bool isAppEnabled = json['applicationEnabled'] as bool? ??
        json['enabled'] as bool? ??
        json['appEnabled'] as bool? ??
        !(json['disabled'] as bool? ?? false);

    return RemoteConfig(
      downloadsEnabled: json['downloadsEnabled'] as bool? ?? true,
      applicationEnabled: isAppEnabled,
      minimumVersion: json['minimumVersion'] as String? ?? '',
      announcements: json['announcements'] != null
          ? AnnouncementsConfig.fromJson(json['announcements'])
          : AnnouncementsConfig(app: [], website: []),
      sources: (json['sources'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, SourceConfig.fromJson(value)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadsEnabled': downloadsEnabled,
      'applicationEnabled': applicationEnabled,
      'minimumVersion': minimumVersion,
      'announcements': announcements.toJson(),
      'sources': sources.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

class AnnouncementsConfig {
  final List<Announcement> app;
  final List<Announcement> website;

  AnnouncementsConfig({required this.app, required this.website});

  factory AnnouncementsConfig.fromJson(Map<String, dynamic> json) {
    return AnnouncementsConfig(
      app: (json['app'] as List?)
              ?.map((e) => Announcement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      website: (json['website'] as List?)
              ?.map((e) => Announcement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'app': app.map((e) => e.toJson()).toList(),
      'website': website.map((e) => e.toJson()).toList(),
    };
  }
}

class Announcement {
  final int id;
  final bool enabled;
  final String title;
  final String message;
  final String type;

  Announcement({
    required this.id,
    required this.enabled,
    required this.title,
    required this.message,
    required this.type,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'info',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enabled': enabled,
      'title': title,
      'message': message,
      'type': type,
    };
  }
}

class SourceConfig {
  final bool disabled;
  final String message;

  SourceConfig({required this.disabled, required this.message});

  factory SourceConfig.fromJson(Map<String, dynamic> json) {
    return SourceConfig(
      disabled: json['disabled'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'disabled': disabled, 'message': message};
  }
}
