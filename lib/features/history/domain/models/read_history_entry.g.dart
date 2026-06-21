// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_history_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReadHistoryEntryCollection on Isar {
  IsarCollection<ReadHistoryEntry> get readHistoryEntrys => this.collection();
}

const ReadHistoryEntrySchema = CollectionSchema(
  name: r'ReadHistoryEntry',
  id: 7052700786598471564,
  properties: {
    r'banner': PropertySchema(id: 0, name: r'banner', type: IsarType.string),
    r'chapterNumber': PropertySchema(
      id: 1,
      name: r'chapterNumber',
      type: IsarType.double,
    ),
    r'chapterTitle': PropertySchema(
      id: 2,
      name: r'chapterTitle',
      type: IsarType.string,
    ),
    r'cover': PropertySchema(id: 3, name: r'cover', type: IsarType.string),
    r'lastUpdated': PropertySchema(
      id: 4,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'mangaId': PropertySchema(id: 5, name: r'mangaId', type: IsarType.string),
    r'mangaIdMal': PropertySchema(
      id: 6,
      name: r'mangaIdMal',
      type: IsarType.string,
    ),
    r'mangaTitle': PropertySchema(
      id: 7,
      name: r'mangaTitle',
      type: IsarType.string,
    ),
    r'positionPage': PropertySchema(
      id: 8,
      name: r'positionPage',
      type: IsarType.long,
    ),
    r'providerId': PropertySchema(
      id: 9,
      name: r'providerId',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 10,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'sourceName': PropertySchema(
      id: 11,
      name: r'sourceName',
      type: IsarType.string,
    ),
    r'totalPages': PropertySchema(
      id: 12,
      name: r'totalPages',
      type: IsarType.long,
    ),
  },

  estimateSize: _readHistoryEntryEstimateSize,
  serialize: _readHistoryEntrySerialize,
  deserialize: _readHistoryEntryDeserialize,
  deserializeProp: _readHistoryEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'chapterNumber': IndexSchema(
      id: -7659654328869413098,
      name: r'chapterNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'chapterNumber',
          type: IndexType.value,
          caseSensitive: false,
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

  getId: _readHistoryEntryGetId,
  getLinks: _readHistoryEntryGetLinks,
  attach: _readHistoryEntryAttach,
  version: '3.3.0',
);

int _readHistoryEntryEstimateSize(
  ReadHistoryEntry object,
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
    final value = object.chapterTitle;
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
  bytesCount += 3 + object.mangaId.length * 3;
  {
    final value = object.mangaIdMal;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mangaTitle.length * 3;
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
  return bytesCount;
}

void _readHistoryEntrySerialize(
  ReadHistoryEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.banner);
  writer.writeDouble(offsets[1], object.chapterNumber);
  writer.writeString(offsets[2], object.chapterTitle);
  writer.writeString(offsets[3], object.cover);
  writer.writeDateTime(offsets[4], object.lastUpdated);
  writer.writeString(offsets[5], object.mangaId);
  writer.writeString(offsets[6], object.mangaIdMal);
  writer.writeString(offsets[7], object.mangaTitle);
  writer.writeLong(offsets[8], object.positionPage);
  writer.writeString(offsets[9], object.providerId);
  writer.writeString(offsets[10], object.sourceId);
  writer.writeString(offsets[11], object.sourceName);
  writer.writeLong(offsets[12], object.totalPages);
}

ReadHistoryEntry _readHistoryEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReadHistoryEntry();
  object.banner = reader.readStringOrNull(offsets[0]);
  object.chapterNumber = reader.readDouble(offsets[1]);
  object.chapterTitle = reader.readStringOrNull(offsets[2]);
  object.cover = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.lastUpdated = reader.readDateTime(offsets[4]);
  object.mangaId = reader.readString(offsets[5]);
  object.mangaIdMal = reader.readStringOrNull(offsets[6]);
  object.mangaTitle = reader.readString(offsets[7]);
  object.positionPage = reader.readLong(offsets[8]);
  object.providerId = reader.readStringOrNull(offsets[9]);
  object.sourceId = reader.readStringOrNull(offsets[10]);
  object.sourceName = reader.readStringOrNull(offsets[11]);
  object.totalPages = reader.readLong(offsets[12]);
  return object;
}

P _readHistoryEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _readHistoryEntryGetId(ReadHistoryEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _readHistoryEntryGetLinks(ReadHistoryEntry object) {
  return [];
}

void _readHistoryEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  ReadHistoryEntry object,
) {
  object.id = id;
}

extension ReadHistoryEntryByIndex on IsarCollection<ReadHistoryEntry> {
  Future<ReadHistoryEntry?> getByChapterNumber(double chapterNumber) {
    return getByIndex(r'chapterNumber', [chapterNumber]);
  }

  ReadHistoryEntry? getByChapterNumberSync(double chapterNumber) {
    return getByIndexSync(r'chapterNumber', [chapterNumber]);
  }

  Future<bool> deleteByChapterNumber(double chapterNumber) {
    return deleteByIndex(r'chapterNumber', [chapterNumber]);
  }

  bool deleteByChapterNumberSync(double chapterNumber) {
    return deleteByIndexSync(r'chapterNumber', [chapterNumber]);
  }

  Future<List<ReadHistoryEntry?>> getAllByChapterNumber(
    List<double> chapterNumberValues,
  ) {
    final values = chapterNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'chapterNumber', values);
  }

  List<ReadHistoryEntry?> getAllByChapterNumberSync(
    List<double> chapterNumberValues,
  ) {
    final values = chapterNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'chapterNumber', values);
  }

  Future<int> deleteAllByChapterNumber(List<double> chapterNumberValues) {
    final values = chapterNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'chapterNumber', values);
  }

  int deleteAllByChapterNumberSync(List<double> chapterNumberValues) {
    final values = chapterNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'chapterNumber', values);
  }

  Future<Id> putByChapterNumber(ReadHistoryEntry object) {
    return putByIndex(r'chapterNumber', object);
  }

  Id putByChapterNumberSync(ReadHistoryEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'chapterNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByChapterNumber(List<ReadHistoryEntry> objects) {
    return putAllByIndex(r'chapterNumber', objects);
  }

  List<Id> putAllByChapterNumberSync(
    List<ReadHistoryEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'chapterNumber', objects, saveLinks: saveLinks);
  }
}

extension ReadHistoryEntryQueryWhereSort
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QWhere> {
  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhere>
  anyChapterNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'chapterNumber'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhere>
  anyLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastUpdated'),
      );
    });
  }
}

extension ReadHistoryEntryQueryWhere
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QWhereClause> {
  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  chapterNumberEqualTo(double chapterNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'chapterNumber',
          value: [chapterNumber],
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  chapterNumberNotEqualTo(double chapterNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'chapterNumber',
                lower: [],
                upper: [chapterNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'chapterNumber',
                lower: [chapterNumber],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'chapterNumber',
                lower: [chapterNumber],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'chapterNumber',
                lower: [],
                upper: [chapterNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  chapterNumberGreaterThan(double chapterNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'chapterNumber',
          lower: [chapterNumber],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  chapterNumberLessThan(double chapterNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'chapterNumber',
          lower: [],
          upper: [chapterNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
  chapterNumberBetween(
    double lowerChapterNumber,
    double upperChapterNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'chapterNumber',
          lower: [lowerChapterNumber],
          includeLower: includeLower,
          upper: [upperChapterNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterWhereClause>
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

extension ReadHistoryEntryQueryFilter
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QFilterCondition> {
  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  bannerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'banner'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  bannerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'banner'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  bannerEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  bannerBetween(
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  bannerMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  bannerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'banner', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  bannerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'banner', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterNumberEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'chapterNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterNumberGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'chapterNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterNumberLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'chapterNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterNumberBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'chapterNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'chapterTitle'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'chapterTitle'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'chapterTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'chapterTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'chapterTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'chapterTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'chapterTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'chapterTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'chapterTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'chapterTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'chapterTitle', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  chapterTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'chapterTitle', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cover'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cover'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverEqualTo(String? value, {bool caseSensitive = true}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverLessThan(
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverBetween(
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverEndsWith(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverContains(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverMatches(String pattern, {bool caseSensitive = true}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cover', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  coverIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cover', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  idBetween(
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdated', value: value),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mangaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mangaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mangaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mangaId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mangaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mangaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mangaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mangaId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mangaId', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mangaId', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'mangaIdMal'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'mangaIdMal'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mangaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mangaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mangaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mangaIdMal',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mangaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mangaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mangaIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mangaIdMal',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mangaIdMal', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaIdMalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mangaIdMal', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mangaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mangaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mangaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mangaTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mangaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mangaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mangaTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mangaTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mangaTitle', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  mangaTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mangaTitle', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  positionPageEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'positionPage', value: value),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  positionPageGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'positionPage',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  positionPageLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'positionPage',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  positionPageBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'positionPage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  providerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  providerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  providerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  providerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceName'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceName'),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceName', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  sourceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceName', value: ''),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  totalPagesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalPages', value: value),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  totalPagesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalPages',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  totalPagesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalPages',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterFilterCondition>
  totalPagesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalPages',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ReadHistoryEntryQueryObject
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QFilterCondition> {}

extension ReadHistoryEntryQueryLinks
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QFilterCondition> {}

extension ReadHistoryEntryQuerySortBy
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QSortBy> {
  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByChapterNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterNumber', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByChapterNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterNumber', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByChapterTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterTitle', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByChapterTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterTitle', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy> sortByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByMangaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaId', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByMangaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaId', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByMangaIdMal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaIdMal', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByMangaIdMalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaIdMal', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByMangaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaTitle', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByMangaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaTitle', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByPositionPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionPage', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByPositionPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionPage', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByTotalPages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPages', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  sortByTotalPagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPages', Sort.desc);
    });
  }
}

extension ReadHistoryEntryQuerySortThenBy
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QSortThenBy> {
  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByChapterNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterNumber', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByChapterNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterNumber', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByChapterTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterTitle', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByChapterTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterTitle', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy> thenByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByMangaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaId', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByMangaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaId', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByMangaIdMal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaIdMal', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByMangaIdMalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaIdMal', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByMangaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaTitle', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByMangaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mangaTitle', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByPositionPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionPage', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByPositionPageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionPage', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByTotalPages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPages', Sort.asc);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QAfterSortBy>
  thenByTotalPagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalPages', Sort.desc);
    });
  }
}

extension ReadHistoryEntryQueryWhereDistinct
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct> {
  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct> distinctByBanner({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'banner', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByChapterNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapterNumber');
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByChapterTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapterTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct> distinctByCover({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cover', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByMangaId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mangaId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByMangaIdMal({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mangaIdMal', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByMangaTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mangaTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByPositionPage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'positionPage');
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByProviderId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'providerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctBySourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctBySourceName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QDistinct>
  distinctByTotalPages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalPages');
    });
  }
}

extension ReadHistoryEntryQueryProperty
    on QueryBuilder<ReadHistoryEntry, ReadHistoryEntry, QQueryProperty> {
  QueryBuilder<ReadHistoryEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReadHistoryEntry, String?, QQueryOperations> bannerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'banner');
    });
  }

  QueryBuilder<ReadHistoryEntry, double, QQueryOperations>
  chapterNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapterNumber');
    });
  }

  QueryBuilder<ReadHistoryEntry, String?, QQueryOperations>
  chapterTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapterTitle');
    });
  }

  QueryBuilder<ReadHistoryEntry, String?, QQueryOperations> coverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cover');
    });
  }

  QueryBuilder<ReadHistoryEntry, DateTime, QQueryOperations>
  lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<ReadHistoryEntry, String, QQueryOperations> mangaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mangaId');
    });
  }

  QueryBuilder<ReadHistoryEntry, String?, QQueryOperations>
  mangaIdMalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mangaIdMal');
    });
  }

  QueryBuilder<ReadHistoryEntry, String, QQueryOperations>
  mangaTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mangaTitle');
    });
  }

  QueryBuilder<ReadHistoryEntry, int, QQueryOperations> positionPageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'positionPage');
    });
  }

  QueryBuilder<ReadHistoryEntry, String?, QQueryOperations>
  providerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'providerId');
    });
  }

  QueryBuilder<ReadHistoryEntry, String?, QQueryOperations> sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<ReadHistoryEntry, String?, QQueryOperations>
  sourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceName');
    });
  }

  QueryBuilder<ReadHistoryEntry, int, QQueryOperations> totalPagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalPages');
    });
  }
}
