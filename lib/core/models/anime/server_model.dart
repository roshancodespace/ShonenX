class BaseServerModel {
  final List<ServerData> sub;
  final List<ServerData> dub;
  final List<ServerData> raw;

  BaseServerModel({
    this.sub = const [],
    this.dub = const [],
    this.raw = const [],
  });

  List<ServerData> flatten() {
    return [...sub, ...dub, ...raw];
  }

  static BaseServerModel defaultServer = BaseServerModel(
    sub: [ServerData(name: "Default", id: "default", isDub: false)],
    dub: [],
  );
}

class ServerData {
  final bool isDub;
  final String? name;
  final String? id;

  ServerData({this.isDub = false, this.name, this.id});

  ServerData copyWith({bool? isDub, String? name, String? id}) {
    return ServerData(
      isDub: isDub ?? this.isDub,
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }
}
