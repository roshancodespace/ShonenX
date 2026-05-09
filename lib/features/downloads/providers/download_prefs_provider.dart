import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/core/providers/storage_provider.dart';

enum FileNameFormat {
  titleAndEpisode,
  episodeOnly;

  String get displayName {
    switch (this) {
      case FileNameFormat.titleAndEpisode:
        return 'Title - Episode';
      case FileNameFormat.episodeOnly:
        return 'Episode Only';
    }
  }

  factory FileNameFormat.fromString(String? value) {
    return FileNameFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FileNameFormat.titleAndEpisode,
    );
  }
}

class DownloadPrefs {
  final String downloadPath;
  final FileNameFormat fileNameFormat;

  const DownloadPrefs({
    required this.downloadPath,
    required this.fileNameFormat,
  });

  DownloadPrefs copyWith({
    String? downloadPath,
    FileNameFormat? fileNameFormat,
  }) {
    return DownloadPrefs(
      downloadPath: downloadPath ?? this.downloadPath,
      fileNameFormat: fileNameFormat ?? this.fileNameFormat,
    );
  }

  factory DownloadPrefs.fromMap(Map<String, dynamic> map, String defaultPath) {
    return DownloadPrefs(
      downloadPath: map['downloadPath'] ?? defaultPath,
      fileNameFormat: FileNameFormat.fromString(map['fileNameFormat']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'downloadPath': downloadPath,
      'fileNameFormat': fileNameFormat.name,
    };
  }
}

class DownloadPrefsNotifier extends AsyncNotifier<DownloadPrefs> {
  static const _key = 'download_prefs';

  @override
  Future<DownloadPrefs> build() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonStr = prefs.getString(_key);

    String defaultPath = '';
    if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      defaultPath = extDir != null
          ? '${extDir.path}/ShonenX'
          : '/storage/emulated/0/ShonenX';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      defaultPath = '${docDir.path}/ShonenX/Downloads';
    }

    if (jsonStr != null) {
      return DownloadPrefs.fromMap(jsonDecode(jsonStr), defaultPath);
    }

    return DownloadPrefs(
      downloadPath: defaultPath,
      fileNameFormat: FileNameFormat.titleAndEpisode,
    );
  }

  Future<void> setDownloadPath(String path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(downloadPath: path));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setFileNameFormat(FileNameFormat format) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(fileNameFormat: format));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }
}

final downloadPrefsProvider =
    AsyncNotifierProvider<DownloadPrefsNotifier, DownloadPrefs>(
      DownloadPrefsNotifier.new,
    );
