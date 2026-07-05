import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/source_engine/models/source_info.dart';

class UnifiedSource {
  final String id;
  final String name;
  final String? lang;
  final String? iconUrl;
  final bool isInbuilt;
  final bool isNsfw;
  final SourceInfo? sourceInfo;
  final bridge.Source? bridgeSource;

  UnifiedSource.fromSourceInfo(this.sourceInfo, [this.bridgeSource])
      : id = sourceInfo!.id,
        name = sourceInfo.name,
        lang = sourceInfo.lang,
        iconUrl = sourceInfo.iconUrl,
        isInbuilt = sourceInfo.type == SourceType.inbuilt,
        isNsfw = sourceInfo.isNsfw;

  UnifiedSource.fromBridgeSource(this.bridgeSource)
      : id = bridgeSource!.id ?? '',
        name = bridgeSource.name ?? 'N/A',
        lang = bridgeSource.lang,
        iconUrl = bridgeSource.iconUrl,
        isInbuilt = false,
        isNsfw = bridgeSource.isNsfw ?? false,
        sourceInfo = null;

  bool get hasUpdate => bridgeSource?.hasUpdate ?? false;
  String? get version => bridgeSource?.version;
  String? get versionLast => bridgeSource?.versionLast;

  bool get effectiveNsfw {
    if (isNsfw) return true;
    final lowerName = name.toLowerCase();
    final lowerId = id.toLowerCase();
    const keywords = [
      '18+',
      'nsfw',
      'hentai',
      'doujin',
      'porn',
      'xvideos',
      'xnxx',
      'hanime',
      'nhentai',
      'rule34',
      'erotic',
      'smut',
    ];
    for (final kw in keywords) {
      if (lowerName.contains(kw) || lowerId.contains(kw)) return true;
    }
    return false;
  }
}
