class VideoServer {
  final String id;
  final String name;
  final ServerType type;

  const VideoServer({
    required this.id,
    required this.name,
    this.type = ServerType.unknown,
  });

  static List<VideoServer> defaultServers(ServerType type) => [
    VideoServer(id: 'default', name: 'Default', type: type),
  ];
}

enum ServerType {
  dub,
  sub,
  raw,
  unknown;

  String get displayName {
    switch (this) {
      case ServerType.dub:
        return 'DUB';
      case ServerType.sub:
        return 'SUB';
      case ServerType.raw:
        return 'RAW';
      case ServerType.unknown:
        return 'UNKNOWN';
    }
  }
}
