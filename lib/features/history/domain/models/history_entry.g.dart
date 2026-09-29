// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHistoryEntryCollection on Isar {
  IsarCollection<HistoryEntry> get historyEntrys => this.collection();
}

const HistoryEntrySchema = CollectionSchema(
  name: r'HistoryEntry',
  id: 2196274019059455532,
  properties: {
    r'banner': PropertySchema(id: 0, name: r'banner', type: IsarType.string),
    r'cover': PropertySchema(id: 1, name: r'cover', type: IsarType.string),
    r'externalIdsJson': PropertySchema(
      id: 2,
      name: r'externalIdsJson',
      type: IsarType.string,
    ),
    r'itemNumber': PropertySchema(
      id: 3,
      name: r'itemNumber',
      type: IsarType.double,
    ),
    r'itemTitle': PropertySchema(
      id: 4,
      name: r'itemTitle',
      type: IsarType.string,
    ),
    r'lastUpdated': PropertySchema(
      id: 5,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'mediaId': PropertySchema(id: 6, name: r'mediaId', type: IsarType.string),
    r'mediaIdMal': PropertySchema(
      id: 7,
      name: r'mediaIdMal',
      type: IsarType.string,
    ),
    r'mediaTitle': PropertySchema(
      id: 8,
      name: r'mediaTitle',
      type: IsarType.string,
    ),
    r'mediaType': PropertySchema(
      id: 9,
      name: r'mediaType',
      type: IsarType.string,
    ),
    r'progress': PropertySchema(id: 10, name: r'progress', type: IsarType.long),
    r'providerId': PropertySchema(
      id: 11,
      name: r'providerId',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 12,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'sourceName': PropertySchema(
      id: 13,
      name: r'sourceName',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 14,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'total': PropertySchema(id: 15, name: r'total', type: IsarType.long),
    r'totalItems': PropertySchema(
      id: 16,
      name: r'totalItems',
      type: IsarType.long,
    ),
  },

  estimateSize: _historyEntryEstimateSize,
  serialize: _historyEntrySerialize,
  deserialize: _historyEntryDeserialize,
  deserializeProp: _historyEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'mediaId_itemNumber': IndexSchema(
      id: 9027115611134764674,
      name: r'mediaId_itemNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'mediaId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'itemNumber',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'mediaType': IndexSchema(
      id: 6292565701790234963,
      name: r'mediaType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'mediaType',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'lastUpdated': IndexSchema(
      id: 8989359681631629925,
      name: r'lastUpdated',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastUpdated',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _historyEntryGetId,
  getLinks: _historyEntryGetLinks,
  attach: _historyEntryAttach,
  version: '3.3.2',
);

int _historyEntryEstimateSize(
  HistoryEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.banner;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cover;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.externalIdsJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.itemTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mediaId.length * 3;
  {
    final value = object.mediaIdMal;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mediaTitle.length * 3;
  bytesCount += 3 + object.mediaType.length * 3;
  {
    final value = object.providerId;
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
    final value = object.sourceName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.thumbnailUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _historyEntrySerialize(
  HistoryEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.banner);
  writer.writeString(offsets[1], object.cover);
  writer.writeString(offsets[2], object.externalIdsJson);
  writer.writeDouble(offsets[3], object.itemNumber);
  writer.writeString(offsets[4], object.itemTitle);
  writer.writeDateTime(offsets[5], object.lastUpdated);
  writer.writeString(offsets[6], object.mediaId);
  writer.writeString(offsets[7], object.mediaIdMal);
  writer.writeString(offsets[8], object.mediaTitle);
  writer.writeString(offsets[9], object.mediaType);
  writer.writeLong(offsets[10], object.progress);
  writer.writeString(offsets[11], object.providerId);
  writer.writeString(offsets[12], object.sourceId);
  writer.writeString(offsets[13], object.sourceName);
  writer.writeString(offsets[14], object.thumbnailUrl);
  writer.writeLong(offsets[15], object.total);
  writer.writeLong(offsets[16], object.totalItems);
}

HistoryEntry _historyEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HistoryEntry();
  object.banner = reader.readStringOrNull(offsets[0]);
  object.cover = reader.readStringOrNull(offsets[1]);
  object.externalIdsJson = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.itemNumber = reader.readDouble(offsets[3]);
  object.itemTitle = reader.readStringOrNull(offsets[4]);
  object.lastUpdated = reader.readDateTime(offsets[5]);
  object.mediaId = reader.readString(offsets[6]);
  object.mediaIdMal = reader.readStringOrNull(offsets[7]);
  object.mediaTitle = reader.readString(offsets[8]);
  object.mediaType = reader.readString(offsets[9]);
  object.progress = reader.readLong(offsets[10]);
  object.providerId = reader.readStringOrNull(offsets[11]);
  object.sourceId = reader.readStringOrNull(offsets[12]);
  object.sourceName = reader.readStringOrNull(offsets[13]);
  object.thumbnailUrl = reader.readStringOrNull(offsets[14]);
  object.total = reader.readLong(offsets[15]);
  object.totalItems = reader.readLongOrNull(offsets[16]);
  return object;
}

P _historyEntryDeserializeProp<P>(
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
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _historyEntryGetId(HistoryEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _historyEntryGetLinks(HistoryEntry object) {
  return [];
}

void _historyEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  HistoryEntry object,
) {
  object.id = id;
}

extension HistoryEntryByIndex on IsarCollection<HistoryEntry> {
  Future<HistoryEntry?> getByMediaIdItemNumber(
    String mediaId,
    double itemNumber,
  ) {
    return getByIndex(r'mediaId_itemNumber', [mediaId, itemNumber]);
  }

  HistoryEntry? getByMediaIdItemNumberSync(String mediaId, double itemNumber) {
    return getByIndexSync(r'mediaId_itemNumber', [mediaId, itemNumber]);
  }

  Future<bool> deleteByMediaIdItemNumber(String mediaId, double itemNumber) {
    return deleteByIndex(r'mediaId_itemNumber', [mediaId, itemNumber]);
  }

  bool deleteByMediaIdItemNumberSync(String mediaId, double itemNumber) {
    return deleteByIndexSync(r'mediaId_itemNumber', [mediaId, itemNumber]);
  }

  Future<List<HistoryEntry?>> getAllByMediaIdItemNumber(
    List<String> mediaIdValues,
    List<double> itemNumberValues,
  ) {
    final len = mediaIdValues.length;
    assert(
      itemNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([mediaIdValues[i], itemNumberValues[i]]);
    }

    return getAllByIndex(r'mediaId_itemNumber', values);
  }

  List<HistoryEntry?> getAllByMediaIdItemNumberSync(
    List<String> mediaIdValues,
    List<double> itemNumberValues,
  ) {
    final len = mediaIdValues.length;
    assert(
      itemNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([mediaIdValues[i], itemNumberValues[i]]);
    }

    return getAllByIndexSync(r'mediaId_itemNumber', values);
  }

  Future<int> deleteAllByMediaIdItemNumber(
    List<String> mediaIdValues,
    List<double> itemNumberValues,
  ) {
    final len = mediaIdValues.length;
    assert(
      itemNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([mediaIdValues[i], itemNumberValues[i]]);
    }

    return deleteAllByIndex(r'mediaId_itemNumber', values);
  }

  int deleteAllByMediaIdItemNumberSync(
    List<String> mediaIdValues,
    List<double> itemNumberValues,
  ) {
    final len = mediaIdValues.length;
    assert(
      itemNumberValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([mediaIdValues[i], itemNumberValues[i]]);
    }

    return deleteAllByIndexSync(r'mediaId_itemNumber', values);
  }

  Future<Id> putByMediaIdItemNumber(HistoryEntry object) {
    return putByIndex(r'mediaId_itemNumber', object);
  }

  Id putByMediaIdItemNumberSync(HistoryEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'mediaId_itemNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMediaIdItemNumber(List<HistoryEntry> objects) {
    return putAllByIndex(r'mediaId_itemNumber', objects);
  }

  List<Id> putAllByMediaIdItemNumberSync(
    List<HistoryEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'mediaId_itemNumber',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension HistoryEntryQueryWhereSort
    on QueryBuilder<HistoryEntry, HistoryEntry, QWhere> {
  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhere> anyLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastUpdated'),
      );
    });
  }
}

extension HistoryEntryQueryWhere
    on QueryBuilder<HistoryEntry, HistoryEntry, QWhereClause> {
  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaIdEqualToAnyItemNumber(String mediaId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'mediaId_itemNumber',
          value: [mediaId],
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaIdNotEqualToAnyItemNumber(String mediaId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [],
                upper: [mediaId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [mediaId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [mediaId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [],
                upper: [mediaId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaIdItemNumberEqualTo(String mediaId, double itemNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'mediaId_itemNumber',
          value: [mediaId, itemNumber],
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaIdEqualToItemNumberNotEqualTo(String mediaId, double itemNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [mediaId],
                upper: [mediaId, itemNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [mediaId, itemNumber],
                includeLower: false,
                upper: [mediaId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [mediaId, itemNumber],
                includeLower: false,
                upper: [mediaId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaId_itemNumber',
                lower: [mediaId],
                upper: [mediaId, itemNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaIdEqualToItemNumberGreaterThan(
    String mediaId,
    double itemNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'mediaId_itemNumber',
          lower: [mediaId, itemNumber],
          includeLower: include,
          upper: [mediaId],
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaIdEqualToItemNumberLessThan(
    String mediaId,
    double itemNumber, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'mediaId_itemNumber',
          lower: [mediaId],
          upper: [mediaId, itemNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaIdEqualToItemNumberBetween(
    String mediaId,
    double lowerItemNumber,
    double upperItemNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'mediaId_itemNumber',
          lower: [mediaId, lowerItemNumber],
          includeLower: includeLower,
          upper: [mediaId, upperItemNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause> mediaTypeEqualTo(
    String mediaType,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'mediaType', value: [mediaType]),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  mediaTypeNotEqualTo(String mediaType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaType',
                lower: [],
                upper: [mediaType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaType',
                lower: [mediaType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaType',
                lower: [mediaType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaType',
                lower: [],
                upper: [mediaType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  lastUpdatedEqualTo(DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'lastUpdated',
          value: [lastUpdated],
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  lastUpdatedNotEqualTo(DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastUpdated',
                lower: [],
                upper: [lastUpdated],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastUpdated',
                lower: [lastUpdated],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastUpdated',
                lower: [lastUpdated],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'lastUpdated',
                lower: [],
                upper: [lastUpdated],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  lastUpdatedGreaterThan(DateTime lastUpdated, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastUpdated',
          lower: [lastUpdated],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  lastUpdatedLessThan(DateTime lastUpdated, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastUpdated',
          lower: [],
          upper: [lastUpdated],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterWhereClause>
  lastUpdatedBetween(
    DateTime lowerLastUpdated,
    DateTime upperLastUpdated, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'lastUpdated',
          lower: [lowerLastUpdated],
          includeLower: includeLower,
          upper: [upperLastUpdated],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension HistoryEntryQueryFilter
    on QueryBuilder<HistoryEntry, HistoryEntry, QFilterCondition> {
  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'banner'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'banner'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> bannerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'banner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'banner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'banner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> bannerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'banner',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'banner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'banner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'banner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> bannerMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'banner',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'banner', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  bannerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'banner', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  coverIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cover'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  coverIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cover'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> coverEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  coverGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> coverLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> coverBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cover',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  coverStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> coverEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> coverContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> coverMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cover',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  coverIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cover', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  coverIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cover', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'externalIdsJson'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'externalIdsJson'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'externalIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'externalIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'externalIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'externalIdsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'externalIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'externalIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'externalIdsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'externalIdsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'externalIdsJson', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  externalIdsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'externalIdsJson', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> idGreaterThan(
    Id value, {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> idLessThan(
    Id value, {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemNumberEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemNumberGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemNumberLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemNumberBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'itemTitle'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'itemTitle'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'itemTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'itemTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'itemTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'itemTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'itemTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'itemTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'itemTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'itemTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'itemTitle', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  itemTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'itemTitle', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdated', value: value),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  lastUpdatedGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUpdated',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  lastUpdatedLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUpdated',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUpdated',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mediaId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mediaId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaId', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mediaId', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'mediaIdMal'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'mediaIdMal'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mediaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mediaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mediaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mediaIdMal',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mediaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mediaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mediaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mediaIdMal',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaIdMal', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaIdMalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mediaIdMal', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mediaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mediaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mediaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mediaTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mediaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mediaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mediaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mediaTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaTitle', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mediaTitle', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mediaType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mediaType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mediaType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mediaType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mediaType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mediaType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mediaType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mediaType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaType', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  mediaTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mediaType', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  progressEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'progress', value: value),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  progressGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'progress',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  progressLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'progress',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  progressBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'progress',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'providerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'providerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'providerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  providerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdGreaterThan(
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdLessThan(
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdBetween(
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdStartsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceName'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceName'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceName', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  sourceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceName', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailUrl'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailUrl'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'thumbnailUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'thumbnailUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'thumbnailUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'thumbnailUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'thumbnailUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'thumbnailUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'thumbnailUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'thumbnailUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbnailUrl', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbnailUrl', value: ''),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> totalEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'total', value: value),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  totalGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'total',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> totalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'total',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition> totalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'total',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  totalItemsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'totalItems'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  totalItemsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'totalItems'),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  totalItemsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalItems', value: value),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  totalItemsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalItems',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  totalItemsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalItems',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterFilterCondition>
  totalItemsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalItems',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension HistoryEntryQueryObject
    on QueryBuilder<HistoryEntry, HistoryEntry, QFilterCondition> {}

extension HistoryEntryQueryLinks
    on QueryBuilder<HistoryEntry, HistoryEntry, QFilterCondition> {}

extension HistoryEntryQuerySortBy
    on QueryBuilder<HistoryEntry, HistoryEntry, QSortBy> {
  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByExternalIdsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalIdsJson', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByExternalIdsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalIdsJson', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByItemNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByItemNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByItemTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemTitle', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByItemTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemTitle', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByMediaIdMal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdMal', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByMediaIdMalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdMal', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByMediaType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaType', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByMediaTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaType', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> sortByTotalItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  sortByTotalItemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.desc);
    });
  }
}

extension HistoryEntryQuerySortThenBy
    on QueryBuilder<HistoryEntry, HistoryEntry, QSortThenBy> {
  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByExternalIdsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalIdsJson', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByExternalIdsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'externalIdsJson', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByItemNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByItemNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByItemTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemTitle', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByItemTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemTitle', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaId', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByMediaIdMal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdMal', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByMediaIdMalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaIdMal', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByMediaType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaType', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByMediaTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaType', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'progress', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy> thenByTotalItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.asc);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QAfterSortBy>
  thenByTotalItemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalItems', Sort.desc);
    });
  }
}

extension HistoryEntryQueryWhereDistinct
    on QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> {
  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByBanner({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'banner', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByCover({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cover', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct>
  distinctByExternalIdsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'externalIdsJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByItemNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemNumber');
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByItemTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByMediaId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByMediaIdMal({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaIdMal', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByMediaTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByMediaType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'progress');
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByProviderId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'providerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctBySourceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctBySourceName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByThumbnailUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }

  QueryBuilder<HistoryEntry, HistoryEntry, QDistinct> distinctByTotalItems() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalItems');
    });
  }
}

extension HistoryEntryQueryProperty
    on QueryBuilder<HistoryEntry, HistoryEntry, QQueryProperty> {
  QueryBuilder<HistoryEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> bannerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'banner');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> coverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cover');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations>
  externalIdsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'externalIdsJson');
    });
  }

  QueryBuilder<HistoryEntry, double, QQueryOperations> itemNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemNumber');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> itemTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemTitle');
    });
  }

  QueryBuilder<HistoryEntry, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<HistoryEntry, String, QQueryOperations> mediaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaId');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> mediaIdMalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaIdMal');
    });
  }

  QueryBuilder<HistoryEntry, String, QQueryOperations> mediaTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaTitle');
    });
  }

  QueryBuilder<HistoryEntry, String, QQueryOperations> mediaTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaType');
    });
  }

  QueryBuilder<HistoryEntry, int, QQueryOperations> progressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'progress');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> providerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'providerId');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> sourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceName');
    });
  }

  QueryBuilder<HistoryEntry, String?, QQueryOperations> thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<HistoryEntry, int, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }

  QueryBuilder<HistoryEntry, int?, QQueryOperations> totalItemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalItems');
    });
  }
}
