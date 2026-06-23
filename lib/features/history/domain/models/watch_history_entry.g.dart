// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWatchHistoryEntryCollection on Isar {
  IsarCollection<WatchHistoryEntry> get watchHistoryEntrys => this.collection();
}

const WatchHistoryEntrySchema = CollectionSchema(
  name: r'WatchHistoryEntry',
  id: 1820870725468747610,
  properties: {
    r'animeId': PropertySchema(id: 0, name: r'animeId', type: IsarType.string),
    r'animeIdMal': PropertySchema(
      id: 1,
      name: r'animeIdMal',
      type: IsarType.string,
    ),
    r'animeTitle': PropertySchema(
      id: 2,
      name: r'animeTitle',
      type: IsarType.string,
    ),
    r'banner': PropertySchema(id: 3, name: r'banner', type: IsarType.string),
    r'cover': PropertySchema(id: 4, name: r'cover', type: IsarType.string),
    r'durationInMilliseconds': PropertySchema(
      id: 5,
      name: r'durationInMilliseconds',
      type: IsarType.long,
    ),
    r'episodeNumber': PropertySchema(
      id: 6,
      name: r'episodeNumber',
      type: IsarType.double,
    ),
    r'episodeTitle': PropertySchema(
      id: 7,
      name: r'episodeTitle',
      type: IsarType.string,
    ),
    r'lastUpdated': PropertySchema(
      id: 8,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'positionInMilliseconds': PropertySchema(
      id: 9,
      name: r'positionInMilliseconds',
      type: IsarType.long,
    ),
    r'providerId': PropertySchema(
      id: 10,
      name: r'providerId',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 11,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'sourceName': PropertySchema(
      id: 12,
      name: r'sourceName',
      type: IsarType.string,
    ),
    r'thumbnailUrl': PropertySchema(
      id: 13,
      name: r'thumbnailUrl',
      type: IsarType.string,
    ),
    r'totalEpisodes': PropertySchema(
      id: 14,
      name: r'totalEpisodes',
      type: IsarType.long,
    ),
  },

  estimateSize: _watchHistoryEntryEstimateSize,
  serialize: _watchHistoryEntrySerialize,
  deserialize: _watchHistoryEntryDeserialize,
  deserializeProp: _watchHistoryEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'episodeNumber': IndexSchema(
      id: -6373633370226080297,
      name: r'episodeNumber',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'episodeNumber',
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

  getId: _watchHistoryEntryGetId,
  getLinks: _watchHistoryEntryGetLinks,
  attach: _watchHistoryEntryAttach,
  version: '3.3.0',
);

int _watchHistoryEntryEstimateSize(
  WatchHistoryEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.animeId.length * 3;
  {
    final value = object.animeIdMal;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.animeTitle.length * 3;
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
    final value = object.episodeTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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

void _watchHistoryEntrySerialize(
  WatchHistoryEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.animeId);
  writer.writeString(offsets[1], object.animeIdMal);
  writer.writeString(offsets[2], object.animeTitle);
  writer.writeString(offsets[3], object.banner);
  writer.writeString(offsets[4], object.cover);
  writer.writeLong(offsets[5], object.durationInMilliseconds);
  writer.writeDouble(offsets[6], object.episodeNumber);
  writer.writeString(offsets[7], object.episodeTitle);
  writer.writeDateTime(offsets[8], object.lastUpdated);
  writer.writeLong(offsets[9], object.positionInMilliseconds);
  writer.writeString(offsets[10], object.providerId);
  writer.writeString(offsets[11], object.sourceId);
  writer.writeString(offsets[12], object.sourceName);
  writer.writeString(offsets[13], object.thumbnailUrl);
  writer.writeLong(offsets[14], object.totalEpisodes);
}

WatchHistoryEntry _watchHistoryEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WatchHistoryEntry();
  object.animeId = reader.readString(offsets[0]);
  object.animeIdMal = reader.readStringOrNull(offsets[1]);
  object.animeTitle = reader.readString(offsets[2]);
  object.banner = reader.readStringOrNull(offsets[3]);
  object.cover = reader.readStringOrNull(offsets[4]);
  object.durationInMilliseconds = reader.readLong(offsets[5]);
  object.episodeNumber = reader.readDouble(offsets[6]);
  object.episodeTitle = reader.readStringOrNull(offsets[7]);
  object.id = id;
  object.lastUpdated = reader.readDateTime(offsets[8]);
  object.positionInMilliseconds = reader.readLong(offsets[9]);
  object.providerId = reader.readStringOrNull(offsets[10]);
  object.sourceId = reader.readStringOrNull(offsets[11]);
  object.sourceName = reader.readStringOrNull(offsets[12]);
  object.thumbnailUrl = reader.readStringOrNull(offsets[13]);
  object.totalEpisodes = reader.readLongOrNull(offsets[14]);
  return object;
}

P _watchHistoryEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _watchHistoryEntryGetId(WatchHistoryEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _watchHistoryEntryGetLinks(
  WatchHistoryEntry object,
) {
  return [];
}

void _watchHistoryEntryAttach(
  IsarCollection<dynamic> col,
  Id id,
  WatchHistoryEntry object,
) {
  object.id = id;
}

extension WatchHistoryEntryByIndex on IsarCollection<WatchHistoryEntry> {
  Future<WatchHistoryEntry?> getByEpisodeNumber(double episodeNumber) {
    return getByIndex(r'episodeNumber', [episodeNumber]);
  }

  WatchHistoryEntry? getByEpisodeNumberSync(double episodeNumber) {
    return getByIndexSync(r'episodeNumber', [episodeNumber]);
  }

  Future<bool> deleteByEpisodeNumber(double episodeNumber) {
    return deleteByIndex(r'episodeNumber', [episodeNumber]);
  }

  bool deleteByEpisodeNumberSync(double episodeNumber) {
    return deleteByIndexSync(r'episodeNumber', [episodeNumber]);
  }

  Future<List<WatchHistoryEntry?>> getAllByEpisodeNumber(
    List<double> episodeNumberValues,
  ) {
    final values = episodeNumberValues.map((e) => [e]).toList();
    return getAllByIndex(r'episodeNumber', values);
  }

  List<WatchHistoryEntry?> getAllByEpisodeNumberSync(
    List<double> episodeNumberValues,
  ) {
    final values = episodeNumberValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'episodeNumber', values);
  }

  Future<int> deleteAllByEpisodeNumber(List<double> episodeNumberValues) {
    final values = episodeNumberValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'episodeNumber', values);
  }

  int deleteAllByEpisodeNumberSync(List<double> episodeNumberValues) {
    final values = episodeNumberValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'episodeNumber', values);
  }

  Future<Id> putByEpisodeNumber(WatchHistoryEntry object) {
    return putByIndex(r'episodeNumber', object);
  }

  Id putByEpisodeNumberSync(WatchHistoryEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'episodeNumber', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEpisodeNumber(List<WatchHistoryEntry> objects) {
    return putAllByIndex(r'episodeNumber', objects);
  }

  List<Id> putAllByEpisodeNumberSync(
    List<WatchHistoryEntry> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'episodeNumber', objects, saveLinks: saveLinks);
  }
}

extension WatchHistoryEntryQueryWhereSort
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QWhere> {
  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhere>
  anyEpisodeNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'episodeNumber'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhere>
  anyLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastUpdated'),
      );
    });
  }
}

extension WatchHistoryEntryQueryWhere
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QWhereClause> {
  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  idBetween(
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  episodeNumberEqualTo(double episodeNumber) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'episodeNumber',
          value: [episodeNumber],
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  episodeNumberNotEqualTo(double episodeNumber) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'episodeNumber',
                lower: [],
                upper: [episodeNumber],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'episodeNumber',
                lower: [episodeNumber],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'episodeNumber',
                lower: [episodeNumber],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'episodeNumber',
                lower: [],
                upper: [episodeNumber],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  episodeNumberGreaterThan(double episodeNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'episodeNumber',
          lower: [episodeNumber],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  episodeNumberLessThan(double episodeNumber, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'episodeNumber',
          lower: [],
          upper: [episodeNumber],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
  episodeNumberBetween(
    double lowerEpisodeNumber,
    double upperEpisodeNumber, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'episodeNumber',
          lower: [lowerEpisodeNumber],
          includeLower: includeLower,
          upper: [upperEpisodeNumber],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterWhereClause>
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

extension WatchHistoryEntryQueryFilter
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QFilterCondition> {
  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'animeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'animeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'animeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'animeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'animeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'animeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'animeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'animeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'animeId', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'animeId', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'animeIdMal'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'animeIdMal'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'animeIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'animeIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'animeIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'animeIdMal',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'animeIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'animeIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'animeIdMal',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'animeIdMal',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'animeIdMal', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeIdMalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'animeIdMal', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'animeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'animeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'animeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'animeTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'animeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'animeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'animeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'animeTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'animeTitle', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  animeTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'animeTitle', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  bannerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'banner'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  bannerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'banner'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  bannerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'banner', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  bannerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'banner', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  coverIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cover'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  coverIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cover'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  coverIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cover', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  coverIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cover', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  durationInMillisecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'durationInMilliseconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  durationInMillisecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationInMilliseconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  durationInMillisecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationInMilliseconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  durationInMillisecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationInMilliseconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeNumberEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'episodeNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeNumberGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'episodeNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeNumberLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'episodeNumber',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeNumberBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'episodeNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'episodeTitle'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'episodeTitle'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'episodeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'episodeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'episodeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'episodeTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'episodeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'episodeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'episodeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'episodeTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'episodeTitle', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  episodeTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'episodeTitle', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdated', value: value),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  positionInMillisecondsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'positionInMilliseconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  positionInMillisecondsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'positionInMilliseconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  positionInMillisecondsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'positionInMilliseconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  positionInMillisecondsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'positionInMilliseconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  providerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  providerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'providerId'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  providerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  providerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'providerId', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceName'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceName'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceName', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  sourceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceName', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'thumbnailUrl'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'thumbnailUrl'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
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

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'thumbnailUrl', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  thumbnailUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'thumbnailUrl', value: ''),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  totalEpisodesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'totalEpisodes'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  totalEpisodesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'totalEpisodes'),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  totalEpisodesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalEpisodes', value: value),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  totalEpisodesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'totalEpisodes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  totalEpisodesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'totalEpisodes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterFilterCondition>
  totalEpisodesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'totalEpisodes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension WatchHistoryEntryQueryObject
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QFilterCondition> {}

extension WatchHistoryEntryQueryLinks
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QFilterCondition> {}

extension WatchHistoryEntryQuerySortBy
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QSortBy> {
  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByAnimeIdMal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeIdMal', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByAnimeIdMalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeIdMal', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByAnimeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByAnimeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByDurationInMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationInMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByDurationInMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationInMilliseconds', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByEpisodeNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByEpisodeNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByEpisodeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeTitle', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByEpisodeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeTitle', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByPositionInMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionInMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByPositionInMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionInMilliseconds', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  sortByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }
}

extension WatchHistoryEntryQuerySortThenBy
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QSortThenBy> {
  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByAnimeIdMal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeIdMal', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByAnimeIdMalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeIdMal', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByAnimeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByAnimeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cover', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByDurationInMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationInMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByDurationInMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'durationInMilliseconds', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByEpisodeNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByEpisodeNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeNumber', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByEpisodeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeTitle', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByEpisodeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'episodeTitle', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByPositionInMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionInMilliseconds', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByPositionInMillisecondsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'positionInMilliseconds', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByProviderId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByProviderIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'providerId', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenBySourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenBySourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceName', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByThumbnailUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByThumbnailUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailUrl', Sort.desc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QAfterSortBy>
  thenByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }
}

extension WatchHistoryEntryQueryWhereDistinct
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct> {
  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByAnimeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByAnimeIdMal({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeIdMal', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByAnimeTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByBanner({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'banner', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByCover({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cover', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByDurationInMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'durationInMilliseconds');
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByEpisodeNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'episodeNumber');
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByEpisodeTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'episodeTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByPositionInMilliseconds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'positionInMilliseconds');
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByProviderId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'providerId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctBySourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctBySourceName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByThumbnailUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QDistinct>
  distinctByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalEpisodes');
    });
  }
}

extension WatchHistoryEntryQueryProperty
    on QueryBuilder<WatchHistoryEntry, WatchHistoryEntry, QQueryProperty> {
  QueryBuilder<WatchHistoryEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WatchHistoryEntry, String, QQueryOperations> animeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeId');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations>
  animeIdMalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeIdMal');
    });
  }

  QueryBuilder<WatchHistoryEntry, String, QQueryOperations>
  animeTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeTitle');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations> bannerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'banner');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations> coverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cover');
    });
  }

  QueryBuilder<WatchHistoryEntry, int, QQueryOperations>
  durationInMillisecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'durationInMilliseconds');
    });
  }

  QueryBuilder<WatchHistoryEntry, double, QQueryOperations>
  episodeNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episodeNumber');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations>
  episodeTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episodeTitle');
    });
  }

  QueryBuilder<WatchHistoryEntry, DateTime, QQueryOperations>
  lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<WatchHistoryEntry, int, QQueryOperations>
  positionInMillisecondsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'positionInMilliseconds');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations>
  providerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'providerId');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations>
  sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations>
  sourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceName');
    });
  }

  QueryBuilder<WatchHistoryEntry, String?, QQueryOperations>
  thumbnailUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailUrl');
    });
  }

  QueryBuilder<WatchHistoryEntry, int?, QQueryOperations>
  totalEpisodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalEpisodes');
    });
  }
}
