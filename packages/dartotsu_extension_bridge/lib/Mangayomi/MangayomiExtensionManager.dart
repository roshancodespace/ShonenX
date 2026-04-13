import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';

import '../dartotsu_extension_bridge.dart';
import 'http/m_client.dart';
import 'lib.dart';

class MangayomiExtensionManager extends GetxController {
  final installedAnimeExtensions = Rx<List<MSource>>([]);
  final availableAnimeExtensions = Rx<List<MSource>>([]);
  final installedMangaExtensions = Rx<List<MSource>>([]);
  final availableMangaExtensions = Rx<List<MSource>>([]);
  final installedNovelExtensions = Rx<List<MSource>>([]);
  final availableNovelExtensions = Rx<List<MSource>>([]);
  final http = MClient.init(reqcopyWith: {'useDartHttpClient': true});

  @override
  void onInit() {
    super.onInit();
    installedAnimeExtensions.bindStream(getExtensionsStream(ItemType.anime));
    installedMangaExtensions.bindStream(getExtensionsStream(ItemType.manga));
    installedNovelExtensions.bindStream(getExtensionsStream(ItemType.novel));
  }

  Stream<List<MSource>> getExtensionsStream(ItemType itemType) async* {
    yield* isar.mSources
        .filter()
        .sourceIdIsNotNull()
        .and()
        .itemTypeEqualTo(itemType)
        .watch(fireImmediately: true);
  }

  Future<List<MSource>> fetchAvailableExtensionsStream(
    ItemType itemType,
    List<String>? repos,
  ) async {
    var sources = <MSource>[];

    if (repos == null || repos.isEmpty) return sources;

    for (final repo in repos) {
      if (repo.trim().isEmpty) continue;
      final req = await http.get(Uri.parse(repo.trim()));
      if (req.statusCode != 200) {
        debugPrint("Failed to fetch sources from $repo: ${req.statusCode}");
        continue;
      }
      final sourceList = (jsonDecode(req.body) as List)
          .map((e) {
            if (e['id'] is String &&
                e['name'] != null &&
                e['site'] != null &&
                e['lang'] != null &&
                e['version'] != null &&
                e['url'] != null &&
                e['iconUrl'] != null) {
              final src = MSource.fromJson(e)
                ..sourceId = e['id'].toString()
                ..apiUrl = ''
                ..appMinVerReq = ''
                ..dateFormat = ''
                ..dateFormatLocale = ''
                ..hasCloudflare = false
                ..headers = ''
                ..isActive = true
                ..isAdded = false
                ..isFullData = false
                ..isNsfw = false
                ..isPinned = false
                ..lastUsed = false
                ..sourceCode = ''
                ..typeSource = ''
                ..versionLast = '0.0.1'
                ..isObsolete = false
                ..isLocal = false
                ..lang = _convertLang(e)
                ..baseUrl = e['site']
                ..sourceCodeUrl = e['url']
                ..sourceCodeLanguage = SourceCodeLanguage.lnreader
                ..itemType = ItemType.novel;
              return src;
            } else {
              return MSource.fromJson(e)
                ..repo = repo
                ..sourceId = e['id'].toString();
            }
          })
          .where((source) => source.itemType == itemType)
          .toList();

      sources.addAll(sourceList);
    }
    switch (itemType) {
      case ItemType.anime:
        availableAnimeExtensions.value = sources;
        break;
      case ItemType.manga:
        availableMangaExtensions.value = sources;
        break;
      case ItemType.novel:
        availableNovelExtensions.value = sources;
        break;
    }

    return sources;
  }

  String _convertLang(dynamic e) {
    final lang = e['lang'];

    if (lang is String) {
      switch (lang) {
        case "‎العربية":
          return "ar";

        case "中文, 汉语, 漢語":
          return "zh";

        case "English":
          return "en";

        case "Français":
          return "fr";

        case "Bahasa Indonesia":
          return "id";

        case "日本語":
          return "ja";

        case "조선말, 한국어":
          return "ko";

        case "Polski":
          return "pl";

        case "Português":
          return "pt";

        case "Русский":
          return "ru";

        case "Español":
          return "es";

        case "ไทย":
          return "th";

        case "Türkçe":
          return "tr";

        case "Українська":
          return "uk";

        case "Tiếng Việt":
          return "vi";

        default:
          return "all";
      }
    }

    return "all";
  }

  Future<void> installSource(Source source) async {
    try {
      var mSource = await getAvailable(source.itemType!, source.id);
      final req = await http.get(Uri.parse(mSource.sourceCodeUrl!));
      final headers = getExtensionService(
        mSource..sourceCode = req.body,
      ).getHeaders();

      var s = mSource
        ..sourceCode = req.body
        ..headers = jsonEncode(headers);

      await isar.writeTxnSync(() async => isar.mSources.putSync(s));
    } catch (e) {
      debugPrint("Error installing source: $e");
      return Future.error(e);
    }
  }

  Future<void> uninstallSource(Source source) async {
    try {
      var mSource = await getInstalled(source.itemType!, source.id);
      await isar.writeTxnSync(
        () async => isar.mSources.deleteSync(mSource.id!),
      );
    } catch (e) {
      debugPrint("Error uninstalling source: $e");
      return Future.error(e);
    }
  }

  Future<void> updateSource(Source source) async {
    try {
      var mSource = await getAvailable(source.itemType!, source.id);
      final req = await http.get(Uri.parse(mSource.sourceCodeUrl!));
      final headers = getExtensionService(
        mSource..sourceCode = req.body,
      ).getHeaders();

      var s = mSource
        ..sourceCode = req.body
        ..version = source.version
        ..headers = jsonEncode(headers);

      await isar.writeTxnSync(() async => isar.mSources.putSync(s));
    } catch (e) {
      debugPrint("Error updating source: $e");
      return Future.error(e);
    }
  }

  Future<MSource> getAvailable(ItemType itemType, String? id) async {
    switch (itemType) {
      case ItemType.anime:
        return availableAnimeExtensions.value.firstWhere(
          (source) => source.sourceId == id,
          orElse: () => throw Exception('Source not found'),
        );
      case ItemType.manga:
        return availableMangaExtensions.value.firstWhere(
          (source) => source.sourceId == id,
          orElse: () => throw Exception('Source not found'),
        );
      case ItemType.novel:
        return availableNovelExtensions.value.firstWhere(
          (source) => source.sourceId == id,
          orElse: () => throw Exception('Source not found'),
        );
    }
  }

  Future<MSource> getInstalled(ItemType itemType, String? id) async {
    switch (itemType) {
      case ItemType.anime:
        return installedAnimeExtensions.value.firstWhere(
          (source) => source.sourceId == id,
          orElse: () => throw Exception('Source not found'),
        );
      case ItemType.manga:
        return installedMangaExtensions.value.firstWhere(
          (source) => source.sourceId == id,
          orElse: () => throw Exception('Source not found'),
        );
      case ItemType.novel:
        return installedNovelExtensions.value.firstWhere(
          (source) => source.sourceId == id,
          orElse: () => throw Exception('Source not found'),
        );
    }
  }
}
