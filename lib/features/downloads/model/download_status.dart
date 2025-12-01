import 'package:hive/hive.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';

part 'download_status.g.dart';

@HiveType(typeId: HiveTypeIds.downloadStatus)
enum DownloadStatus {
  @HiveField(0)
  downloaded,
  @HiveField(1)
  downloading,
  @HiveField(2)
  paused,
  @HiveField(3)
  error,
  @HiveField(4)
  queued,
  @HiveField(5)
  failed
}
