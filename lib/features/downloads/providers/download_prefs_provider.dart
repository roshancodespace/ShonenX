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

class DownloadPrefs {
  final String downloadPath;
  final FileNameFormat fileNameFormat;
  final bool createSubfolders;
  final bool useOneDM;
  final bool wifiOnly;
  final int concurrentDownloads;
  final DuplicateAction duplicateAction;
  final bool autoDeleteWatched;

  const DownloadPrefs({
    required this.downloadPath,
    required this.fileNameFormat,
    this.createSubfolders = true,
    this.useOneDM = false,
    this.wifiOnly = true,
    this.concurrentDownloads = 2,
    this.duplicateAction = DuplicateAction.skip,
    this.autoDeleteWatched = false,
  });

  DownloadPrefs copyWith({
    String? downloadPath,
    FileNameFormat? fileNameFormat,
    bool? createSubfolders,
    bool? useOneDM,
    bool? wifiOnly,
    int? concurrentDownloads,
    DuplicateAction? duplicateAction,
    bool? autoDeleteWatched,
  }) {
    return DownloadPrefs(
      downloadPath: downloadPath ?? this.downloadPath,
      fileNameFormat: fileNameFormat ?? this.fileNameFormat,
      createSubfolders: createSubfolders ?? this.createSubfolders,
      useOneDM: useOneDM ?? this.useOneDM,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      duplicateAction: duplicateAction ?? this.duplicateAction,
      autoDeleteWatched: autoDeleteWatched ?? this.autoDeleteWatched,
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
      duplicateAction: DuplicateAction.fromString(map['duplicateAction']),
      autoDeleteWatched: map['autoDeleteWatched'] ?? false,
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
      'duplicateAction': duplicateAction.name,
      'autoDeleteWatched': autoDeleteWatched,
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
      duplicateAction: DuplicateAction.skip,
      autoDeleteWatched: false,
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
}

final downloadPrefsProvider =
    AsyncNotifierProvider<DownloadPrefsNotifier, DownloadPrefs>(
      DownloadPrefsNotifier.new,
    );
