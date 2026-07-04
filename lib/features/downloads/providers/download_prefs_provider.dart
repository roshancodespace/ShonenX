import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

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

enum DuplicateAction {
  skip,
  overwrite;

  String get displayName {
    switch (this) {
      case DuplicateAction.skip:
        return 'Skip Download';
      case DuplicateAction.overwrite:
        return 'Overwrite Existing';
    }
  }

  factory DuplicateAction.fromString(String? value) {
    return DuplicateAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DuplicateAction.skip,
    );
  }
}

enum RemuxerPreference {
  auto,
  builtin;

  String get displayName {
    switch (this) {
      case RemuxerPreference.auto:
        return 'Auto (FFmpeg if available)';
      case RemuxerPreference.builtin:
        return 'Built-in (TS Concatenation)';
    }
  }

  factory RemuxerPreference.fromString(String? value) {
    return RemuxerPreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RemuxerPreference.auto,
    );
  }
}

class DownloadPrefs {
  final String downloadPath;
  final FileNameFormat fileNameFormat;
  final bool createSubfolders;
  final bool useOneDM;
  final bool wifiOnly;
  final int concurrentDownloads;
  final int concurrentSegments;
  final DuplicateAction duplicateAction;
  final bool autoDeleteWatched;
  final RemuxerPreference remuxerPreference;

  const DownloadPrefs({
    required this.downloadPath,
    required this.fileNameFormat,
    this.createSubfolders = true,
    this.useOneDM = false,
    this.wifiOnly = true,
    this.concurrentDownloads = 2,
    this.concurrentSegments = 4,
    this.duplicateAction = DuplicateAction.skip,
    this.autoDeleteWatched = false,
    this.remuxerPreference = RemuxerPreference.auto,
  });

  DownloadPrefs copyWith({
    String? downloadPath,
    FileNameFormat? fileNameFormat,
    bool? createSubfolders,
    bool? useOneDM,
    bool? wifiOnly,
    int? concurrentDownloads,
    int? concurrentSegments,
    DuplicateAction? duplicateAction,
    bool? autoDeleteWatched,
    RemuxerPreference? remuxerPreference,
  }) {
    return DownloadPrefs(
      downloadPath: downloadPath ?? this.downloadPath,
      fileNameFormat: fileNameFormat ?? this.fileNameFormat,
      createSubfolders: createSubfolders ?? this.createSubfolders,
      useOneDM: useOneDM ?? this.useOneDM,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      concurrentSegments: concurrentSegments ?? this.concurrentSegments,
      duplicateAction: duplicateAction ?? this.duplicateAction,
      autoDeleteWatched: autoDeleteWatched ?? this.autoDeleteWatched,
      remuxerPreference: remuxerPreference ?? this.remuxerPreference,
    );
  }

  factory DownloadPrefs.fromMap(Map<String, dynamic> map, String defaultPath) {
    return DownloadPrefs(
      downloadPath: map['downloadPath'] ?? defaultPath,
      fileNameFormat: FileNameFormat.fromString(map['fileNameFormat']),
      createSubfolders: map['createSubfolders'] ?? true,
      useOneDM: map['useOneDM'] ?? false,
      wifiOnly: map['wifiOnly'] ?? true,
      concurrentDownloads: map['concurrentDownloads'] ?? 2,
      concurrentSegments: map['concurrentSegments'] ?? 4,
      duplicateAction: DuplicateAction.fromString(map['duplicateAction']),
      autoDeleteWatched: map['autoDeleteWatched'] ?? false,
      remuxerPreference: RemuxerPreference.fromString(map['remuxerPreference']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'downloadPath': downloadPath,
      'fileNameFormat': fileNameFormat.name,
      'createSubfolders': createSubfolders,
      'useOneDM': useOneDM,
      'wifiOnly': wifiOnly,
      'concurrentDownloads': concurrentDownloads,
      'concurrentSegments': concurrentSegments,
      'duplicateAction': duplicateAction.name,
      'autoDeleteWatched': autoDeleteWatched,
      'remuxerPreference': remuxerPreference.name,
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
      createSubfolders: true,
      useOneDM: false,
      wifiOnly: true,
      concurrentDownloads: 2,
      concurrentSegments: 4,
      duplicateAction: DuplicateAction.skip,
      autoDeleteWatched: false,
      remuxerPreference: RemuxerPreference.auto,
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

  Future<void> setUseOneDM(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(useOneDM: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setCreateSubfolders(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(createSubfolders: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setWifiOnly(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(wifiOnly: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setConcurrentDownloads(int value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(concurrentDownloads: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setConcurrentSegments(int value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(concurrentSegments: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setDuplicateAction(DuplicateAction value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(duplicateAction: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setAutoDeleteWatched(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(autoDeleteWatched: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setRemuxerPreference(RemuxerPreference value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(remuxerPreference: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<String> getDefaultDownloadPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/ShonenX';
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      return '${docDir.path}/ShonenX/Downloads';
    }
  }

  Future<int> resetAndMigrateStorage({required bool moveFiles}) async {
    final newPath = await getDefaultDownloadPath();
    return migrateStorageToPath(newPath, moveFiles: moveFiles);
  }

  Future<int> migrateStorageToPath(
    String newPath, {
    required bool moveFiles,
  }) async {
    final oldPath = state.value?.downloadPath;
    int movedCount = 0;

    if (moveFiles && oldPath != null && oldPath != newPath) {
      try {
        final oldDir = Directory(oldPath);
        if (await oldDir.exists()) {
          final newDir = Directory(newPath);
          if (!await newDir.exists()) {
            await newDir.create(recursive: true);
          }

          final entities = await oldDir.list(recursive: true).toList();
          for (final entity in entities) {
            if (entity is File &&
                (entity.path.endsWith('.mp4') || entity.path.endsWith('.ts'))) {
              final relPath = entity.path.substring(oldPath.length);
              final targetFilePath = '$newPath$relPath';
              final lastSlash = targetFilePath.lastIndexOf('/');
              if (lastSlash != -1) {
                final targetFileDir = Directory(
                  targetFilePath.substring(0, lastSlash),
                );
                if (!await targetFileDir.exists()) {
                  await targetFileDir.create(recursive: true);
                }
              }
              try {
                await entity.rename(targetFilePath);
                movedCount++;
              } catch (_) {
                try {
                  await entity.copy(targetFilePath);
                  await entity.delete();
                  movedCount++;
                } catch (_) {}
              }
            }
          }
        }
      } catch (_) {
        // Ignore file listing or permission errors to ensure path is always updated below
      }
    }

    await setDownloadPath(newPath);
    return movedCount;
  }

  Future<List<File>> getMigratableFiles() async {
    final oldPath = state.value?.downloadPath;
    if (oldPath == null) return [];
    final oldDir = Directory(oldPath);
    if (!await oldDir.exists()) return [];

    final files = <File>[];
    try {
      final entities = await oldDir.list(recursive: true).toList();
      for (final entity in entities) {
        if (entity is File) {
          final pathLower = entity.path.toLowerCase();
          if (pathLower.contains('/node_modules/') ||
              pathLower.contains('/.pnpm/') ||
              pathLower.contains('/.git/') ||
              pathLower.contains('/.local/') ||
              pathLower.contains('/.cache/') ||
              pathLower.contains('/.pub-cache/') ||
              pathLower.contains('/.zsh-cache')) {
            continue;
          }
          if (pathLower.endsWith('.mp4') || pathLower.endsWith('.mkv')) {
            files.add(entity);
          }
        }
      }
    } catch (_) {}
    return files;
  }

  Future<int> migrateSelectedFiles(
    String newPath,
    List<File> filesToMove,
  ) async {
    final oldPath = state.value?.downloadPath ?? '';
    int movedCount = 0;

    final newDir = Directory(newPath);
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }

    for (final entity in filesToMove) {
      if (await entity.exists()) {
        String relPath = '';
        if (oldPath.isNotEmpty && entity.path.startsWith(oldPath)) {
          relPath = entity.path.substring(oldPath.length);
        } else {
          relPath = '/${entity.uri.pathSegments.last}';
        }
        if (!relPath.startsWith('/')) relPath = '/$relPath';

        final targetFilePath = '$newPath$relPath';
        final lastSlash = targetFilePath.lastIndexOf('/');
        if (lastSlash != -1) {
          final targetFileDir = Directory(
            targetFilePath.substring(0, lastSlash),
          );
          if (!await targetFileDir.exists()) {
            await targetFileDir.create(recursive: true);
          }
        }
        try {
          await entity.rename(targetFilePath);
          movedCount++;
        } catch (_) {
          try {
            await entity.copy(targetFilePath);
            await entity.delete();
            movedCount++;
          } catch (_) {}
        }
      }
    }

    await setDownloadPath(newPath);
    return movedCount;
  }
}

final downloadPrefsProvider =
    AsyncNotifierProvider<DownloadPrefsNotifier, DownloadPrefs>(
      DownloadPrefsNotifier.new,
    );
