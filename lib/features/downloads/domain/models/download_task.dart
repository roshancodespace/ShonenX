import 'package:isar_community/isar.dart';

part 'download_task.g.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  canceled,
}

@embedded
class DownloadHeader {
  late String key;
  late String value;

  DownloadHeader();

  DownloadHeader.create({required this.key, required this.value});

  factory DownloadHeader.fromMapEntry(MapEntry<String, String> entry) {
    return DownloadHeader.create(key: entry.key, value: entry.value);
  }

  static List<DownloadHeader> fromMap(Map<String, String> map) {
    return map.entries.map(DownloadHeader.fromMapEntry).toList();
  }

  MapEntry<String, String> toMapEntry() {
    return MapEntry(key, value);
  }
}

@collection
class DownloadTask {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String url = '';

  String mediaId = '';
  double episodeNumber = 0.0;
  String savePath = '';
  String fileName = '';

  List<DownloadHeader> headers = [];

  @enumerated
  DownloadStatus status = DownloadStatus.pending;

  bool isM3u8 = false;

  double progress = 0.0;
  int totalBytes = 0;
  int downloadedBytes = 0;

  @ignore
  int downloadedSegments = 0;
  @ignore
  int totalSegments = 0;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  @ignore
  Map<String, String> get headersMap {
    return {for (final header in headers) header.key: header.value};
  }

  set headersMap(Map<String, String>? value) {
    headers =
        value?.entries
            .map((e) => DownloadHeader.create(key: e.key, value: e.value))
            .toList() ??
        [];
  }
}
