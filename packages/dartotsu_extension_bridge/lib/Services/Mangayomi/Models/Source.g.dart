// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Source.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMSourceCollection on Isar {
  IsarCollection<MSource> get mSources => this.collection();
}

const MSourceSchema = CollectionSchema(
  name: r'Sources',
  id: 897746782445124704,
  properties: {
    r'additionalParams': PropertySchema(
      id: 0,
      name: r'additionalParams',
      type: IsarType.string,
    ),
    r'apiUrl': PropertySchema(id: 1, name: r'apiUrl', type: IsarType.string),
    r'appMinVerReq': PropertySchema(
      id: 2,
      name: r'appMinVerReq',
      type: IsarType.string,
    ),
    r'baseUrl': PropertySchema(id: 3, name: r'baseUrl', type: IsarType.string),
    r'dateFormat': PropertySchema(
      id: 4,
      name: r'dateFormat',
      type: IsarType.string,
    ),
    r'dateFormatLocale': PropertySchema(
      id: 5,
      name: r'dateFormatLocale',
      type: IsarType.string,
    ),
    r'hasCloudflare': PropertySchema(
      id: 6,
      name: r'hasCloudflare',
      type: IsarType.bool,
    ),
    r'headers': PropertySchema(id: 7, name: r'headers', type: IsarType.string),
    r'iconUrl': PropertySchema(id: 8, name: r'iconUrl', type: IsarType.string),
    r'isActive': PropertySchema(id: 9, name: r'isActive', type: IsarType.bool),
    r'isAdded': PropertySchema(id: 10, name: r'isAdded', type: IsarType.bool),
    r'isFullData': PropertySchema(
      id: 11,
      name: r'isFullData',
      type: IsarType.bool,
    ),
    r'isLocal': PropertySchema(id: 12, name: r'isLocal', type: IsarType.bool),
    r'isManga': PropertySchema(id: 13, name: r'isManga', type: IsarType.bool),
    r'isNsfw': PropertySchema(id: 14, name: r'isNsfw', type: IsarType.bool),
    r'isObsolete': PropertySchema(
      id: 15,
      name: r'isObsolete',
      type: IsarType.bool,
    ),
    r'isPinned': PropertySchema(id: 16, name: r'isPinned', type: IsarType.bool),
    r'isTorrent': PropertySchema(
      id: 17,
      name: r'isTorrent',
      type: IsarType.bool,
    ),
    r'itemType': PropertySchema(
      id: 18,
      name: r'itemType',
      type: IsarType.byte,
      enumMap: _MSourceitemTypeEnumValueMap,
    ),
    r'lang': PropertySchema(id: 19, name: r'lang', type: IsarType.string),
    r'lastUsed': PropertySchema(id: 20, name: r'lastUsed', type: IsarType.bool),
    r'name': PropertySchema(id: 21, name: r'name', type: IsarType.string),
    r'repo': PropertySchema(id: 22, name: r'repo', type: IsarType.string),
    r'sourceCode': PropertySchema(
      id: 23,
      name: r'sourceCode',
      type: IsarType.string,
    ),
    r'sourceCodeLanguage': PropertySchema(
      id: 24,
      name: r'sourceCodeLanguage',
      type: IsarType.byte,
      enumMap: _MSourcesourceCodeLanguageEnumValueMap,
    ),
    r'sourceCodeUrl': PropertySchema(
      id: 25,
      name: r'sourceCodeUrl',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 26,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'typeSource': PropertySchema(
      id: 27,
      name: r'typeSource',
      type: IsarType.string,
    ),
    r'version': PropertySchema(id: 28, name: r'version', type: IsarType.string),
    r'versionLast': PropertySchema(
      id: 29,
      name: r'versionLast',
      type: IsarType.string,
    ),
  },

  estimateSize: _mSourceEstimateSize,
  serialize: _mSourceSerialize,
  deserialize: _mSourceDeserialize,
  deserializeProp: _mSourceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _mSourceGetId,
  getLinks: _mSourceGetLinks,
  attach: _mSourceAttach,
  version: '3.3.0',
);

int _mSourceEstimateSize(
  MSource object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.additionalParams;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.apiUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.appMinVerReq;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.baseUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateFormat;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.dateFormatLocale;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.headers;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.iconUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lang;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.repo;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceCodeUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.sourceId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.typeSource;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.version;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.versionLast;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _mSourceSerialize(
  MSource object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.additionalParams);
  writer.writeString(offsets[1], object.apiUrl);
  writer.writeString(offsets[2], object.appMinVerReq);
  writer.writeString(offsets[3], object.baseUrl);
  writer.writeString(offsets[4], object.dateFormat);
  writer.writeString(offsets[5], object.dateFormatLocale);
  writer.writeBool(offsets[6], object.hasCloudflare);
  writer.writeString(offsets[7], object.headers);
  writer.writeString(offsets[8], object.iconUrl);
  writer.writeBool(offsets[9], object.isActive);
  writer.writeBool(offsets[10], object.isAdded);
  writer.writeBool(offsets[11], object.isFullData);
  writer.writeBool(offsets[12], object.isLocal);
  writer.writeBool(offsets[13], object.isManga);
  writer.writeBool(offsets[14], object.isNsfw);
  writer.writeBool(offsets[15], object.isObsolete);
  writer.writeBool(offsets[16], object.isPinned);
  writer.writeBool(offsets[17], object.isTorrent);
  writer.writeByte(offsets[18], object.itemType.index);
  writer.writeString(offsets[19], object.lang);
  writer.writeBool(offsets[20], object.lastUsed);
  writer.writeString(offsets[21], object.name);
  writer.writeString(offsets[22], object.repo);
  writer.writeString(offsets[23], object.sourceCode);
  writer.writeByte(offsets[24], object.sourceCodeLanguage.index);
  writer.writeString(offsets[25], object.sourceCodeUrl);
  writer.writeString(offsets[26], object.sourceId);
  writer.writeString(offsets[27], object.typeSource);
  writer.writeString(offsets[28], object.version);
  writer.writeString(offsets[29], object.versionLast);
}

MSource _mSourceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MSource(
    additionalParams: reader.readStringOrNull(offsets[0]),
    apiUrl: reader.readStringOrNull(offsets[1]),
    appMinVerReq: reader.readStringOrNull(offsets[2]),
    baseUrl: reader.readStringOrNull(offsets[3]),
    dateFormat: reader.readStringOrNull(offsets[4]),
    dateFormatLocale: reader.readStringOrNull(offsets[5]),
    hasCloudflare: reader.readBoolOrNull(offsets[6]),
    headers: reader.readStringOrNull(offsets[7]),
    iconUrl: reader.readStringOrNull(offsets[8]),
    id: id,
    isActive: reader.readBoolOrNull(offsets[9]),
    isAdded: reader.readBoolOrNull(offsets[10]),
    isFullData: reader.readBoolOrNull(offsets[11]),
    isLocal: reader.readBoolOrNull(offsets[12]),
    isManga: reader.readBoolOrNull(offsets[13]),
    isNsfw: reader.readBoolOrNull(offsets[14]),
    isObsolete: reader.readBoolOrNull(offsets[15]),
    isPinned: reader.readBoolOrNull(offsets[16]),
    itemType:
        _MSourceitemTypeValueEnumMap[reader.readByteOrNull(offsets[18])] ??
        ItemType.manga,
    lang: reader.readStringOrNull(offsets[19]),
    lastUsed: reader.readBoolOrNull(offsets[20]),
    name: reader.readStringOrNull(offsets[21]),
    repo: reader.readStringOrNull(offsets[22]),
    sourceCode: reader.readStringOrNull(offsets[23]),
    sourceCodeLanguage:
        _MSourcesourceCodeLanguageValueEnumMap[reader.readByteOrNull(
          offsets[24],
        )] ??
        SourceCodeLanguage.dart,
    sourceCodeUrl: reader.readStringOrNull(offsets[25]),
    sourceId: reader.readStringOrNull(offsets[26]),
    typeSource: reader.readStringOrNull(offsets[27]),
    version: reader.readStringOrNull(offsets[28]),
    versionLast: reader.readStringOrNull(offsets[29]),
  );
  return object;
}

P _mSourceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readBoolOrNull(offset)) as P;
    case 10:
      return (reader.readBoolOrNull(offset)) as P;
    case 11:
      return (reader.readBoolOrNull(offset)) as P;
    case 12:
      return (reader.readBoolOrNull(offset)) as P;
    case 13:
      return (reader.readBoolOrNull(offset)) as P;
    case 14:
      return (reader.readBoolOrNull(offset)) as P;
    case 15:
      return (reader.readBoolOrNull(offset)) as P;
    case 16:
      return (reader.readBoolOrNull(offset)) as P;
    case 17:
      return (reader.readBool(offset)) as P;
    case 18:
      return (_MSourceitemTypeValueEnumMap[reader.readByteOrNull(offset)] ??
              ItemType.manga)
          as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readBoolOrNull(offset)) as P;
    case 21:
      return (reader.readStringOrNull(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (_MSourcesourceCodeLanguageValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              SourceCodeLanguage.dart)
          as P;
    case 25:
      return (reader.readStringOrNull(offset)) as P;
    case 26:
      return (reader.readStringOrNull(offset)) as P;
    case 27:
      return (reader.readStringOrNull(offset)) as P;
    case 28:
      return (reader.readStringOrNull(offset)) as P;
    case 29:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MSourceitemTypeEnumValueMap = {'manga': 0, 'anime': 1, 'novel': 2};
const _MSourceitemTypeValueEnumMap = {
  0: ItemType.manga,
  1: ItemType.anime,
  2: ItemType.novel,
};
const _MSourcesourceCodeLanguageEnumValueMap = {
  'dart': 0,
  'javascript': 1,
  'lnreader': 2,
};
const _MSourcesourceCodeLanguageValueEnumMap = {
  0: SourceCodeLanguage.dart,
  1: SourceCodeLanguage.javascript,
  2: SourceCodeLanguage.lnreader,
};

Id _mSourceGetId(MSource object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _mSourceGetLinks(MSource object) {
  return [];
}

void _mSourceAttach(IsarCollection<dynamic> col, Id id, MSource object) {
  object.id = id;
}

extension MSourceQueryWhereSort on QueryBuilder<MSource, MSource, QWhere> {
  QueryBuilder<MSource, MSource, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MSourceQueryWhere on QueryBuilder<MSource, MSource, QWhereClause> {
  QueryBuilder<MSource, MSource, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MSource, MSource, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MSource, MSource, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension MSourceQueryFilter
    on QueryBuilder<MSource, MSource, QFilterCondition> {
  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'additionalParams'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'additionalParams'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> additionalParamsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'additionalParams',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'additionalParams',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'additionalParams',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> additionalParamsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'additionalParams',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'additionalParams',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'additionalParams',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'additionalParams',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> additionalParamsMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'additionalParams',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'additionalParams', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  additionalParamsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'additionalParams', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'apiUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'apiUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'apiUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'apiUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'apiUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'apiUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'apiUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'apiUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'apiUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'apiUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'apiUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> apiUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'apiUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'appMinVerReq'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  appMinVerReqIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'appMinVerReq'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'appMinVerReq',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'appMinVerReq',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'appMinVerReq',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'appMinVerReq',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'appMinVerReq',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'appMinVerReq',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'appMinVerReq',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'appMinVerReq',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> appMinVerReqIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'appMinVerReq', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  appMinVerReqIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'appMinVerReq', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'baseUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'baseUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'baseUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'baseUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'baseUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'baseUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'baseUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'baseUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'baseUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'baseUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'baseUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> baseUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'baseUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dateFormat'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dateFormat'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateFormat',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateFormat',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateFormat', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateFormat', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'dateFormatLocale'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'dateFormatLocale'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatLocaleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'dateFormatLocale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'dateFormatLocale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'dateFormatLocale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatLocaleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'dateFormatLocale',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'dateFormatLocale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'dateFormatLocale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'dateFormatLocale',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> dateFormatLocaleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'dateFormatLocale',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'dateFormatLocale', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  dateFormatLocaleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'dateFormatLocale', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> hasCloudflareIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'hasCloudflare'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  hasCloudflareIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'hasCloudflare'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> hasCloudflareEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'hasCloudflare', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'headers'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'headers'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'headers',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'headers',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'headers',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'headers',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'headers',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'headers',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'headers',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'headers',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'headers', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> headersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'headers', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'iconUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'iconUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'iconUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'iconUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'iconUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'iconUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'iconUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'iconUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'iconUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'iconUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'iconUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> iconUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'iconUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isActiveIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isActive'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isActiveIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isActive'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isActiveEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isActive', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isAddedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isAdded'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isAddedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isAdded'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isAddedEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isAdded', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isFullDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isFullData'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isFullDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isFullData'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isFullDataEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFullData', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isLocalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isLocal'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isLocalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isLocal'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isLocalEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isLocal', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isMangaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isManga'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isMangaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isManga'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isMangaEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isManga', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isNsfwIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isNsfw'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isNsfwIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isNsfw'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isNsfwEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isNsfw', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isObsoleteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isObsolete'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isObsoleteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isObsolete'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isObsoleteEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isObsolete', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isPinnedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'isPinned'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isPinnedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'isPinned'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isPinnedEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isPinned', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> isTorrentEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isTorrent', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> itemTypeEqualTo(
    ItemType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemType', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> itemTypeGreaterThan(
    ItemType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> itemTypeLessThan(
    ItemType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> itemTypeBetween(
    ItemType lower,
    ItemType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lang'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lang'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lang',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lang',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lang',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lang',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lang',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lang',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lang',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lang',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lang', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> langIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lang', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> lastUsedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUsed'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> lastUsedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUsed'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> lastUsedEqualTo(
    bool? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUsed', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'name'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'name'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'repo'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'repo'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'repo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'repo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'repo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'repo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'repo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'repo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'repo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'repo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'repo', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> repoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'repo', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceCode'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceCode'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceCode', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceCode', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  sourceCodeLanguageEqualTo(SourceCodeLanguage value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceCodeLanguage', value: value),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  sourceCodeLanguageGreaterThan(
    SourceCodeLanguage value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceCodeLanguage',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  sourceCodeLanguageLessThan(SourceCodeLanguage value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceCodeLanguage',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  sourceCodeLanguageBetween(
    SourceCodeLanguage lower,
    SourceCodeLanguage upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceCodeLanguage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceCodeUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  sourceCodeUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceCodeUrl'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceCodeUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  sourceCodeUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceCodeUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceCodeUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceCodeUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceCodeUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceCodeUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceCodeUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceCodeUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceCodeUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceCodeUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  sourceCodeUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceCodeUrl', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'typeSource'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'typeSource'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'typeSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'typeSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'typeSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'typeSource',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'typeSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'typeSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'typeSource',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'typeSource',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'typeSource', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> typeSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'typeSource', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'version'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'version'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'version',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'version',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'version',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'version', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'version', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'versionLast'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'versionLast'),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'versionLast',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'versionLast',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'versionLast',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'versionLast',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'versionLast',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'versionLast',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'versionLast',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'versionLast',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition> versionLastIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'versionLast', value: ''),
      );
    });
  }

  QueryBuilder<MSource, MSource, QAfterFilterCondition>
  versionLastIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'versionLast', value: ''),
      );
    });
  }
}

extension MSourceQueryObject
    on QueryBuilder<MSource, MSource, QFilterCondition> {}

extension MSourceQueryLinks
    on QueryBuilder<MSource, MSource, QFilterCondition> {}

extension MSourceQuerySortBy on QueryBuilder<MSource, MSource, QSortBy> {
  QueryBuilder<MSource, MSource, QAfterSortBy> sortByAdditionalParams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalParams', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByAdditionalParamsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalParams', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByApiUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByApiUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByAppMinVerReq() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appMinVerReq', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByAppMinVerReqDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appMinVerReq', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByBaseUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByBaseUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByDateFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByDateFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByDateFormatLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormatLocale', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByDateFormatLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormatLocale', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByHasCloudflare() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCloudflare', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByHasCloudflareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCloudflare', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByHeaders() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByHeadersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIconUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIconUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdded', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdded', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsFullData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullData', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsFullDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullData', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsLocal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocal', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsLocalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocal', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsManga() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isManga', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsMangaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isManga', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsNsfw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNsfw', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsNsfwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNsfw', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsObsolete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isObsolete', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsObsoleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isObsolete', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsTorrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTorrent', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByIsTorrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTorrent', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemType', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByItemTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemType', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByLang() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lang', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByLangDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lang', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByLastUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByLastUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByRepo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repo', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByRepoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repo', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCode', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCode', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceCodeLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeLanguage', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceCodeLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeLanguage', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceCodeUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceCodeUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByTypeSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeSource', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByTypeSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeSource', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByVersionLast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionLast', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> sortByVersionLastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionLast', Sort.desc);
    });
  }
}

extension MSourceQuerySortThenBy
    on QueryBuilder<MSource, MSource, QSortThenBy> {
  QueryBuilder<MSource, MSource, QAfterSortBy> thenByAdditionalParams() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalParams', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByAdditionalParamsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'additionalParams', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByApiUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByApiUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'apiUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByAppMinVerReq() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appMinVerReq', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByAppMinVerReqDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'appMinVerReq', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByBaseUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByBaseUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByDateFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByDateFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormat', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByDateFormatLocale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormatLocale', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByDateFormatLocaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateFormatLocale', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByHasCloudflare() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCloudflare', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByHasCloudflareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasCloudflare', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByHeaders() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByHeadersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'headers', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIconUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIconUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iconUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdded', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsAddedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAdded', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsFullData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullData', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsFullDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFullData', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsLocal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocal', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsLocalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocal', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsManga() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isManga', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsMangaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isManga', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsNsfw() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNsfw', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsNsfwDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isNsfw', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsObsolete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isObsolete', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsObsoleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isObsolete', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsTorrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTorrent', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByIsTorrentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTorrent', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemType', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByItemTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemType', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByLang() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lang', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByLangDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lang', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByLastUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByLastUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsed', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByRepo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repo', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByRepoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repo', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCode', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCode', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceCodeLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeLanguage', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceCodeLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeLanguage', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceCodeUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeUrl', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceCodeUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceCodeUrl', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByTypeSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeSource', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByTypeSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeSource', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByVersionLast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionLast', Sort.asc);
    });
  }

  QueryBuilder<MSource, MSource, QAfterSortBy> thenByVersionLastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'versionLast', Sort.desc);
    });
  }
}

extension MSourceQueryWhereDistinct
    on QueryBuilder<MSource, MSource, QDistinct> {
  QueryBuilder<MSource, MSource, QDistinct> distinctByAdditionalParams({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'additionalParams',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByApiUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'apiUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByAppMinVerReq({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'appMinVerReq', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByBaseUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByDateFormat({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateFormat', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByDateFormatLocale({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'dateFormatLocale',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByHasCloudflare() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasCloudflare');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByHeaders({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'headers', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIconUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iconUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsAdded() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAdded');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsFullData() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFullData');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsLocal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLocal');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsManga() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isManga');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsNsfw() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isNsfw');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsObsolete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isObsolete');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByIsTorrent() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTorrent');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemType');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByLang({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lang', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByLastUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsed');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByRepo({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctBySourceCode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctBySourceCodeLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceCodeLanguage');
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctBySourceCodeUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceCodeUrl',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctBySourceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByTypeSource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeSource', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByVersion({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MSource, MSource, QDistinct> distinctByVersionLast({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'versionLast', caseSensitive: caseSensitive);
    });
  }
}

extension MSourceQueryProperty
    on QueryBuilder<MSource, MSource, QQueryProperty> {
  QueryBuilder<MSource, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> additionalParamsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'additionalParams');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> apiUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'apiUrl');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> appMinVerReqProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'appMinVerReq');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> baseUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseUrl');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> dateFormatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateFormat');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> dateFormatLocaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateFormatLocale');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> hasCloudflareProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasCloudflare');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> headersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'headers');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> iconUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iconUrl');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isAddedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAdded');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isFullDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFullData');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isLocalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLocal');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isMangaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isManga');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isNsfwProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isNsfw');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isObsoleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isObsolete');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<MSource, bool, QQueryOperations> isTorrentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTorrent');
    });
  }

  QueryBuilder<MSource, ItemType, QQueryOperations> itemTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemType');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> langProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lang');
    });
  }

  QueryBuilder<MSource, bool?, QQueryOperations> lastUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsed');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> repoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repo');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> sourceCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceCode');
    });
  }

  QueryBuilder<MSource, SourceCodeLanguage, QQueryOperations>
  sourceCodeLanguageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceCodeLanguage');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> sourceCodeUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceCodeUrl');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> typeSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeSource');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }

  QueryBuilder<MSource, String?, QQueryOperations> versionLastProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'versionLast');
    });
  }
}
