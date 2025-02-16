class BaseServerModel {
  final List<ServerData> sub;
  final List<ServerData> dub;
  final List<ServerData> raw;

  BaseServerModel(
      {this.sub = const [], this.dub = const [], this.raw = const []});
}

class ServerData {
  final String? name;
  final int? id;

  ServerData({this.name, this.id});
}
