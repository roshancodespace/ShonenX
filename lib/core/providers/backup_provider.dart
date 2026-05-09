import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/database/database_provider.dart';
import 'package:shonenx/core/providers/storage_provider.dart';
import 'package:shonenx/core/services/backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final isar = ref.watch(databaseProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return BackupService(isar, prefs);
});
