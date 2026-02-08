import 'dart:convert';

import 'package:dartotsu_extension_bridge/Models/Source.dart';
import 'package:dartotsu_extension_bridge/Services/Mangayomi/http/m_client.dart';

import '../../Extensions/Extensions.dart';

class SoraExtensions extends Extension {
  @override
  Future<List<Source>> fetchAvailableAnimeExtensions(
    List<String>? repos,
  ) async {
    var client = MClient.init();
    var res = await client.get(
      Uri.parse(
        "https://git.luna-app.eu/50n50/sources/raw/branch/main/index.json",
      ),
    );
    var sources = jsonDecode(res.body) as Map<String, dynamic>;
    var sourceList = sources.entries
        .map(
          (e) => Source(
            id: e.value['sourceName'],
            name: e.value['sourceName'],
            itemType: ItemType.anime,
            lang: e.value['language'],
            version: e.value['version'],
          ),
        )
        .toList();
    sourceList.forEach((element) => print(element.name));
    return [];
  }

  @override
  Future<void> initialize() {
    throw UnimplementedError();
  }

  @override
  Future<void> installSource(Source source) {
    throw UnimplementedError();
  }

  @override
  Future<void> uninstallSource(Source source) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSource(Source source) {
    throw UnimplementedError();
  }
}
