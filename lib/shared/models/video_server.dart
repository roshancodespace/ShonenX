class VideoServer {
  final String id;
  final String name;
  final ServerType type;

  const VideoServer({
    required this.id,
    required this.name,
    this.type = ServerType.unknown,
  });
}

enum ServerType { dub, sub, unknown }
