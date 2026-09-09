class DiscordRpcCustomSettings {
  final String idleActivity;
  final String idleDetails;
  final bool enableDetailsPresence;
  final bool enablePlayerPresence;
  final bool enableReaderPresence;

  const DiscordRpcCustomSettings({
    this.idleActivity = 'Browsing Catalog',
    this.idleDetails = 'Exploring Anime & Manga',
    this.enableDetailsPresence = true,
    this.enablePlayerPresence = true,
    this.enableReaderPresence = true,
  });

  DiscordRpcCustomSettings copyWith({
    String? idleActivity,
    String? idleDetails,
    bool? enableDetailsPresence,
    bool? enablePlayerPresence,
    bool? enableReaderPresence,
  }) {
    return DiscordRpcCustomSettings(
      idleActivity: idleActivity ?? this.idleActivity,
      idleDetails: idleDetails ?? this.idleDetails,
      enableDetailsPresence:
          enableDetailsPresence ?? this.enableDetailsPresence,
      enablePlayerPresence: enablePlayerPresence ?? this.enablePlayerPresence,
      enableReaderPresence: enableReaderPresence ?? this.enableReaderPresence,
    );
  }

  Map<String, dynamic> toJson() => {
    'idleActivity': idleActivity,
    'idleDetails': idleDetails,
    'enableDetailsPresence': enableDetailsPresence,
    'enablePlayerPresence': enablePlayerPresence,
    'enableReaderPresence': enableReaderPresence,
  };

  factory DiscordRpcCustomSettings.fromJson(Map<String, dynamic> json) {
    return DiscordRpcCustomSettings(
      idleActivity: json['idleActivity'] as String? ?? 'Browsing Catalog',
      idleDetails: json['idleDetails'] as String? ?? 'Exploring Anime & Manga',
      enableDetailsPresence: json['enableDetailsPresence'] as bool? ?? true,
      enablePlayerPresence: json['enablePlayerPresence'] as bool? ?? true,
      enableReaderPresence: json['enableReaderPresence'] as bool? ?? true,
    );
  }
}
