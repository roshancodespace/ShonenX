import 'package:isar_community/isar.dart';

import '../../Models/Source.dart';
import '../Eval/dart/model/m_source.dart' as m;

part 'Source.g.dart';

@collection
@Name("Sources")
class MSource {
  Id? id;

  String? sourceId;

  String? name;

  String? baseUrl;

  String? lang;

  bool? isActive;

  bool? isAdded;

  bool? isPinned;

  bool? isNsfw;

  String? sourceCode;

  String? sourceCodeUrl;

  String? typeSource;

  String? iconUrl;

  bool? isFullData;

  bool? hasCloudflare;

  bool? lastUsed;

  String? dateFormat;

  String? dateFormatLocale;

  String? apiUrl;

  String? version;

  String? versionLast;

  String? headers;

  bool? isManga;

  @enumerated
  late ItemType itemType;

  String? appMinVerReq;

  String? additionalParams;

  bool? isLocal;

  bool? isObsolete;

  String? repo;
  @enumerated
  SourceCodeLanguage sourceCodeLanguage = SourceCodeLanguage.dart;

  MSource({
    this.id = 0,
    this.sourceId = null,
    this.name = '',
    this.baseUrl = '',
    this.lang = '',
    this.typeSource = '',
    this.iconUrl = '',
    this.dateFormat = '',
    this.dateFormatLocale = '',
    this.isActive = true,
    this.isAdded = false,
    this.isNsfw = false,
    this.isFullData = false,
    this.hasCloudflare = false,
    this.isPinned = false,
    this.lastUsed = false,
    this.apiUrl = "",
    this.sourceCodeUrl = "",
    this.version = "0.0.1",
    this.versionLast = "0.0.1",
    this.sourceCode = '',
    this.headers = '',
    this.isManga = true,
    this.itemType = ItemType.manga,
    this.appMinVerReq = "",
    this.additionalParams = "",
    this.isLocal = false,
    this.isObsolete = false,
    this.sourceCodeLanguage = SourceCodeLanguage.dart,
    this.repo,
  });

  MSource.fromJson(Map<String, dynamic> json) {
    apiUrl = json['apiUrl'];
    appMinVerReq = json['appMinVerReq'];
    baseUrl = json['baseUrl'];
    dateFormat = json['dateFormat'];
    dateFormatLocale = json['dateFormatLocale'];
    hasCloudflare = json['hasCloudflare'];
    headers = json['headers'];
    iconUrl = json['iconUrl'];
    id = json['id'] is int ? json['id'] : null;
    sourceId = json['sourceId'].toString();
    isActive = json['isActive'];
    isAdded = json['isAdded'];
    isFullData = json['isFullData'];
    isManga = json['isManga'];
    itemType = ItemType.values[json['itemType'] ?? 0];
    isNsfw = json['isNsfw'];
    isPinned = json['isPinned'];
    lang = json['lang'];
    lastUsed = json['lastUsed'];
    name = json['name'];
    sourceCode = json['sourceCode'];
    sourceCodeUrl = json['sourceCodeUrl'];
    typeSource = json['typeSource'];
    version = json['version'];
    versionLast = json['versionLast'];
    additionalParams = json['additionalParams'] ?? "";
    isObsolete = json['isObsolete'];
    isLocal = json['isLocal'];
    sourceCodeLanguage =
        SourceCodeLanguage.values[json['sourceCodeLanguage'] ?? 0];
    repo = json['repo'];
  }

  Map<String, dynamic> toJson() => {
    'apiUrl': apiUrl,
    'appMinVerReq': appMinVerReq,
    'baseUrl': baseUrl,
    'dateFormat': dateFormat,
    'dateFormatLocale': dateFormatLocale,
    'hasCloudflare': hasCloudflare,
    'headers': headers,
    'iconUrl': iconUrl,
    'id': id,
    'sourceId': sourceId,
    'isActive': isActive,
    'isAdded': isAdded,
    'isFullData': isFullData,
    'isManga': isManga,
    'itemType': itemType.index,
    'isNsfw': isNsfw,
    'isPinned': isPinned,
    'lang': lang,
    'lastUsed': lastUsed,
    'name': name,
    'sourceCode': sourceCode,
    'sourceCodeUrl': sourceCodeUrl,
    'typeSource': typeSource,
    'version': version,
    'versionLast': versionLast,
    'additionalParams': additionalParams,
    'sourceCodeLanguage': sourceCodeLanguage.index,
    'isObsolete': isObsolete,
    'isLocal': isLocal,
    'repo': repo,
  };

  bool get isTorrent => (typeSource?.toLowerCase() ?? "") == "torrent";

  m.MSource toMSource() {
    return m.MSource(
      id: id,
      name: name,
      hasCloudflare: hasCloudflare,
      isFullData: isFullData,
      lang: lang,
      baseUrl: baseUrl,
      apiUrl: apiUrl,
      dateFormat: dateFormat,
      dateFormatLocale: dateFormatLocale,
      additionalParams: additionalParams,
    );
  }
}

enum SourceCodeLanguage { dart, javascript, lnreader }
