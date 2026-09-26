class DiscordRpcCustomSettings {
  final String idleActivity;
  final String idleDetails;
  final bool enableDetailsPresence;
  final bool enablePlayerPresence;
  final bool enableReaderPresence;
  final bool showEpisodeNumber;
  final bool showProgress;
  final bool showMediaImage;
  final bool showButtons;

  const DiscordRpcCustomSettings({
    this.idleActivity = 'Browsing Catalog',
    this.idleDetails = 'Exploring Anime & Manga',
    this.enableDetailsPresence = true,
    this.enablePlayerPresence = true,
    this.enableReaderPresence = true,
    this.showEpisodeNumber = true,
    this.showProgress = true,
    this.showMediaImage = true,
    this.showButtons = true,
  });

  DiscordRpcCustomSettings copyWith({
    String? idleActivity,
    String? idleDetails,
    bool? enableDetailsPresence,
    bool? enablePlayerPresence,
    bool? enableReaderPresence,
    bool? showEpisodeNumber,
    bool? showProgress,
    bool? showMediaImage,
    bool? showButtons,
  }) {
    return DiscordRpcCustomSettings(
      idleActivity: idleActivity ?? this.idleActivity,
      idleDetails: idleDetails ?? this.idleDetails,
      enableDetailsPresence:
          enableDetailsPresence ?? this.enableDetailsPresence,
      enablePlayerPresence: enablePlayerPresence ?? this.enablePlayerPresence,
      enableReaderPresence: enableReaderPresence ?? this.enableReaderPresence,
      showEpisodeNumber: showEpisodeNumber ?? this.showEpisodeNumber,
      showProgress: showProgress ?? this.showProgress,
      showMediaImage: showMediaImage ?? this.showMediaImage,
      showButtons: showButtons ?? this.showButtons,
    );
  }

  Map<String, dynamic> toJson() => {
    'idleActivity': idleActivity,
    'idleDetails': idleDetails,
    'enableDetailsPresence': enableDetailsPresence,
    'enablePlayerPresence': enablePlayerPresence,
    'enableReaderPresence': enableReaderPresence,
    'showEpisodeNumber': showEpisodeNumber,
    'showProgress': showProgress,
    'showMediaImage': showMediaImage,
    'showButtons': showButtons,
  };

  factory DiscordRpcCustomSettings.fromJson(Map<String, dynamic> json) {
    return DiscordRpcCustomSettings(
      idleActivity: json['idleActivity'] as String? ?? 'Browsing Catalog',
      idleDetails: json['idleDetails'] as String? ?? 'Exploring Anime & Manga',
      enableDetailsPresence: json['enableDetailsPresence'] as bool? ?? true,
      enablePlayerPresence: json['enablePlayerPresence'] as bool? ?? true,
      enableReaderPresence: json['enableReaderPresence'] as bool? ?? true,
      showEpisodeNumber: json['showEpisodeNumber'] as bool? ?? true,
      showProgress: json['showProgress'] as bool? ?? true,
      showMediaImage: json['showMediaImage'] as bool? ?? true,
      showButtons: json['showButtons'] as bool? ?? true,
    );
  }
}
