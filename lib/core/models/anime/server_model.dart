class BaseServerModel {
  final List<ServerData> sub;
  final List<ServerData> dub;
  final List<ServerData> raw;

  BaseServerModel(
      {this.sub = const [], this.dub = const [], this.raw = const []});

  List<ServerData> flatten() {
    return [...sub, ...dub, ...raw];
  }
}

class ServerData {
  final bool isDub;
  final String? name;
  final String? id;

  ServerData({this.isDub = false, this.name, this.id});
}
