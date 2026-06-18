enum ReleaseChannel { stable, test }

class RemoteConfig {
  final ChannelConfig? stable;
  final ChannelConfig? test;
  final Announcement? announcement;
  final Map<String, SourceConfig> sources;

  RemoteConfig({
    this.stable,
    this.test,
    this.announcement,
    this.sources = const {},
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      stable: json['stable'] != null
          ? ChannelConfig.fromJson(json['stable'])
          : null,
      test: json['test'] != null ? ChannelConfig.fromJson(json['test']) : null,
      announcement: json['announcement'] != null
          ? Announcement.fromJson(json['announcement'])
          : null,
      sources:
          (json['sources'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, SourceConfig.fromJson(value)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stable': stable?.toJson(),
      'test': test?.toJson(),
      'announcement': announcement?.toJson(),
      'sources': sources.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  // Helper method to get config based on active channel
  ChannelConfig? getChannelConfig(ReleaseChannel channel) {
    return channel == ReleaseChannel.stable ? stable : test;
  }
}

class ChannelConfig {
  final int updateId;
  final String version;
  final bool forceUpdate;
  final String message;
  final String apk;

  ChannelConfig({
    required this.updateId,
    required this.version,
    required this.forceUpdate,
    required this.message,
    required this.apk,
  });

  factory ChannelConfig.fromJson(Map<String, dynamic> json) {
    return ChannelConfig(
      updateId: json['updateId'] as int? ?? 0,
      version: json['version'] as String? ?? '1.0.0',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      apk: json['apk'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updateId': updateId,
      'version': version,
      'forceUpdate': forceUpdate,
      'message': message,
      'apk': apk,
    };
  }
}

class Announcement {
  final String id;
  final String message;

  Announcement({required this.id, required this.message});

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'message': message};
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
