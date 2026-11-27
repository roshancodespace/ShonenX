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

enum RemuxerPreference {
  builtin,
  ffmpeg;

  String get displayName {
    switch (this) {
      case RemuxerPreference.builtin:
        return 'Built-in (Recommended)';
      case RemuxerPreference.ffmpeg:
        return 'FFmpeg (External)';
    }
  }

  factory RemuxerPreference.fromString(String? value) {
    return RemuxerPreference.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RemuxerPreference.builtin,
    );
  }
}

enum MangaDownloadFormat {
  folder,
  cbz;

  String get displayName {
    switch (this) {
      case MangaDownloadFormat.folder:
        return 'Image Folder (Pages)';
      case MangaDownloadFormat.cbz:
        return 'CBZ Archive (.cbz)';
    }
  }

  factory MangaDownloadFormat.fromString(String? value) {
    return MangaDownloadFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MangaDownloadFormat.folder,
    );
  }
}

class DownloadPrefs {
  final String downloadPath;
  final FileNameFormat fileNameFormat;
  final bool createSubfolders;
  final bool separateMediaFolders;
  final bool useOneDM;
  final bool wifiOnly;
  final int concurrentDownloads;
  final int concurrentSegments;
  final RemuxerPreference remuxerPreference;
  final MangaDownloadFormat mangaFormat;
  final int concurrentMangaPages;

  const DownloadPrefs({
    required this.downloadPath,
    required this.fileNameFormat,
    this.createSubfolders = true,
    this.separateMediaFolders = true,
    this.useOneDM = false,
    this.wifiOnly = true,
    this.concurrentDownloads = 2,
    this.concurrentSegments = 4,
    this.remuxerPreference = RemuxerPreference.builtin,
    this.mangaFormat = MangaDownloadFormat.folder,
    this.concurrentMangaPages = 4,
  });

  /// Returns the base directory for Anime or Manga downloads.
  String mediaRootPath({required bool isManga}) {
    if (!separateMediaFolders) return downloadPath;
    final sub = isManga ? 'Manga' : 'Anime';
    return '$downloadPath/$sub';
  }

  DownloadPrefs copyWith({
    String? downloadPath,
    FileNameFormat? fileNameFormat,
    bool? createSubfolders,
    bool? separateMediaFolders,
    bool? useOneDM,
    bool? wifiOnly,
    int? concurrentDownloads,
    int? concurrentSegments,
    RemuxerPreference? remuxerPreference,
    MangaDownloadFormat? mangaFormat,
    int? concurrentMangaPages,
  }) {
    return DownloadPrefs(
      downloadPath: downloadPath ?? this.downloadPath,
      fileNameFormat: fileNameFormat ?? this.fileNameFormat,
      createSubfolders: createSubfolders ?? this.createSubfolders,
      separateMediaFolders: separateMediaFolders ?? this.separateMediaFolders,
      useOneDM: useOneDM ?? this.useOneDM,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      concurrentSegments: concurrentSegments ?? this.concurrentSegments,
      remuxerPreference: remuxerPreference ?? this.remuxerPreference,
      mangaFormat: mangaFormat ?? this.mangaFormat,
      concurrentMangaPages: concurrentMangaPages ?? this.concurrentMangaPages,
    );
  }

  factory DownloadPrefs.fromMap(Map<String, dynamic> map, String defaultPath) {
    return DownloadPrefs(
      downloadPath: map['downloadPath'] ?? defaultPath,
      fileNameFormat: FileNameFormat.fromString(map['fileNameFormat']),
      createSubfolders: map['createSubfolders'] ?? true,
      separateMediaFolders: map['separateMediaFolders'] ?? true,
      useOneDM: map['useOneDM'] ?? false,
      wifiOnly: map['wifiOnly'] ?? true,
      concurrentDownloads: map['concurrentDownloads'] ?? 2,
      concurrentSegments: map['concurrentSegments'] ?? 4,
      remuxerPreference: RemuxerPreference.fromString(map['remuxerPreference']),
      mangaFormat: MangaDownloadFormat.fromString(map['mangaFormat']),
      concurrentMangaPages: map['concurrentMangaPages'] ?? 4,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'downloadPath': downloadPath,
      'fileNameFormat': fileNameFormat.name,
      'createSubfolders': createSubfolders,
      'separateMediaFolders': separateMediaFolders,
      'useOneDM': useOneDM,
      'wifiOnly': wifiOnly,
      'concurrentDownloads': concurrentDownloads,
      'concurrentSegments': concurrentSegments,
      'remuxerPreference': remuxerPreference.name,
      'mangaFormat': mangaFormat.name,
      'concurrentMangaPages': concurrentMangaPages,
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
      fileNameFormat: FileNameFormat.episodeOnly,
      createSubfolders: true,
      useOneDM: false,
      wifiOnly: true,
      concurrentDownloads: 2,
      concurrentSegments: 4,
      remuxerPreference: RemuxerPreference.builtin,
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

  Future<void> setRemuxerPreference(RemuxerPreference value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(remuxerPreference: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setSeparateMediaFolders(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(separateMediaFolders: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setMangaFormat(MangaDownloadFormat value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(state.value!.copyWith(mangaFormat: value));
    await prefs.setString(_key, jsonEncode(state.value!.toMap()));
  }

  Future<void> setConcurrentMangaPages(int value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = AsyncData(
      state.value!.copyWith(concurrentMangaPages: value.clamp(1, 8)),
    );
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
          if (pathLower.endsWith('.mp4') ||
              pathLower.endsWith('.mkv') ||
              pathLower.endsWith('.cbz') ||
              pathLower.endsWith('.jpg') ||
              pathLower.endsWith('.jpeg') ||
              pathLower.endsWith('.png') ||
              pathLower.endsWith('.webp')) {
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
