import 'package:isar_community/isar.dart';

part 'download_task.g.dart';

enum DownloadStatus { pending, downloading, paused, completed, failed, canceled }

@collection
class DownloadTask {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String url = '';

  String mediaId = '';
  double episodeNumber = 0.0;
  String savePath = '';
  String fileName = '';

  @enumerated
  DownloadStatus status = DownloadStatus.pending;

  double progress = 0.0;
  int totalBytes = 0;
  int downloadedBytes = 0;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}