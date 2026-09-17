import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class OfflinePlaybackProgress {
  final String filePath;
  final int positionMs;
  final int durationMs;
  final DateTime lastUpdated;

  const OfflinePlaybackProgress({
    required this.filePath,
    required this.positionMs,
    required this.durationMs,
    required this.lastUpdated,
  });

  double get progress =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => durationMs > 0 && positionMs >= durationMs * 0.9;

  String? get remainingText {
    if (durationMs <= 0 || isCompleted) return null;
    final remainingMs = durationMs - positionMs;
    if (remainingMs <= 10000) return null;
    return formatTimeRemaining(remainingMs);
  }

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory OfflinePlaybackProgress.fromJson(Map<String, dynamic> json) =>
      OfflinePlaybackProgress(
        filePath: json['filePath'] as String? ?? '',
        positionMs: json['positionMs'] as int? ?? 0,
        durationMs: json['durationMs'] as int? ?? 0,
        lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
            DateTime.now(),
      );
}

class OfflineProgressRepository {
  final SharedPreferences _prefs;
  static const String _prefix = 'kurox_offline_progress_';

  OfflineProgressRepository(this._prefs);

  String _keyFor(String filePath) {
    // Normalize path separators and use lowercase for consistent matching
    final normalized = filePath.replaceAll(r'\', '/').toLowerCase();
    return '$_prefix${normalized.hashCode}';
  }

  Future<void> saveProgress(
    String filePath,
    int positionMs,
    int durationMs,
  ) async {
    if (positionMs < 2000) return; // Don't persist initial buffer

    final progress = OfflinePlaybackProgress(
      filePath: filePath,
      positionMs: positionMs,
      durationMs: durationMs,
      lastUpdated: DateTime.now(),
    );

    final key = _keyFor(filePath);
    await _prefs.setString(key, jsonEncode(progress.toJson()));
  }

  OfflinePlaybackProgress? getProgress(String filePath) {
    final key = _keyFor(filePath);
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return OfflinePlaybackProgress.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearProgress(String filePath) async {
    final key = _keyFor(filePath);
    await _prefs.remove(key);
  }
}

final offlineProgressRepositoryProvider =
    Provider<OfflineProgressRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineProgressRepository(prefs);
}, name: 'offlineProgressRepositoryProvider');

final offlineProgressProvider =
    Provider.family<OfflinePlaybackProgress?, String>((ref, filePath) {
  final repo = ref.watch(offlineProgressRepositoryProvider);
  return repo.getProgress(filePath);
}, name: 'offlineProgressProvider');
