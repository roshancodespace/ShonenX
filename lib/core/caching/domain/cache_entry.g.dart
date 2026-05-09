// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCacheEntryCollection on Isar {
  IsarCollection<CacheEntry> get cacheEntrys => this.collection();
}

const CacheEntrySchema = CollectionSchema(
  name: r'CacheEntry',
  id: 1901957776030515961,
  properties: {
    r'bodyBytes': PropertySchema(
      id: 0,
      name: r'bodyBytes',
      type: IsarType.longList,
    ),
    r'etag': PropertySchema(id: 1, name: r'etag', type: IsarType.string),
    r'expiry': PropertySchema(id: 2, name: r'expiry', type: IsarType.dateTime),
    r'key': PropertySchema(id: 3, name: r'key', type: IsarType.string),
    r'lastModified': PropertySchema(
      id: 4,
      name: r'lastModified',
      type: IsarType.string,
    ),
  },

  estimateSize: _cacheEntryEstimateSize,
  serialize: _cacheEntrySerialize,
  deserialize: _cacheEntryDeserialize,
  deserializeProp: _cacheEntryDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _cacheEntryGetId,
  getLinks: _cacheEntryGetLinks,
  attach: _cacheEntryAttach,
  version: '3.3.0',
);

int _cacheEntryEstimateSize(
  CacheEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bodyBytes.length * 8;
  {
    final value = object.etag;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.key.length * 3;
  {
    final value = object.lastModified;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cacheEntrySerialize(
  CacheEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLongList(offsets[0], object.bodyBytes);
  writer.writeString(offsets[1], object.etag);
  writer.writeDateTime(offsets[2], object.expiry);
  writer.writeString(offsets[3], object.key);
  writer.writeString(offsets[4], object.lastModified);
}

CacheEntry _cacheEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CacheEntry();
  object.bodyBytes = reader.readLongList(offsets[0]) ?? [];
  object.etag = reader.readStringOrNull(offsets[1]);
  object.expiry = reader.readDateTime(offsets[2]);
  object.id = id;
  object.key = reader.readString(offsets[3]);
  object.lastModified = reader.readStringOrNull(offsets[4]);
  return object;
}

P _cacheEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongList(offset) ?? []) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cacheEntryGetId(CacheEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cacheEntryGetLinks(CacheEntry object) {
  return [];
}

void _cacheEntryAttach(IsarCollection<dynamic> col, Id id, CacheEntry object) {
  object.id = id;
}

extension CacheEntryByIndex on IsarCollection<CacheEntry> {
  Future<CacheEntry?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  CacheEntry? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<CacheEntry?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<CacheEntry?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(CacheEntry object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(CacheEntry object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<CacheEntry> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<CacheEntry> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension CacheEntryQueryWhereSort
    on QueryBuilder<CacheEntry, CacheEntry, QWhere> {
  QueryBuilder<CacheEntry, CacheEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CacheEntryQueryWhere
    on QueryBuilder<CacheEntry, CacheEntry, QWhereClause> {
  QueryBuilder<CacheEntry, CacheEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<CacheEntry, CacheEntry, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterWhereClause> idBetween(
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

  QueryBuilder<CacheEntry, CacheEntry, QAfterWhereClause> keyEqualTo(
    String key,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'key', value: [key]),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterWhereClause> keyNotEqualTo(
    String key,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension CacheEntryQueryFilter
    on QueryBuilder<CacheEntry, CacheEntry, QFilterCondition> {
  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'bodyBytes', value: value),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bodyBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'bodyBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bodyBytes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'bodyBytes', length, true, length, true);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'bodyBytes', 0, true, 0, true);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'bodyBytes', 0, false, 999999, true);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'bodyBytes', 0, true, length, include);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'bodyBytes', length, include, 999999, true);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  bodyBytesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'bodyBytes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'etag'),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'etag'),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'etag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'etag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'etag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'etag',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'etag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'etag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'etag',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'etag',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'etag', value: ''),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> etagIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'etag', value: ''),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> expiryEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'expiry', value: value),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> expiryGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expiry',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> expiryLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expiry',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> expiryBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expiry',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'key',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition> keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastModified'),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastModified'),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastModified',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastModified',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastModified',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastModified',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastModified',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastModified',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastModified',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastModified',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastModified', value: ''),
      );
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterFilterCondition>
  lastModifiedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastModified', value: ''),
      );
    });
  }
}

extension CacheEntryQueryObject
    on QueryBuilder<CacheEntry, CacheEntry, QFilterCondition> {}

extension CacheEntryQueryLinks
    on QueryBuilder<CacheEntry, CacheEntry, QFilterCondition> {}

extension CacheEntryQuerySortBy
    on QueryBuilder<CacheEntry, CacheEntry, QSortBy> {
  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByEtag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etag', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByEtagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etag', Sort.desc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByExpiry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiry', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByExpiryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiry', Sort.desc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByLastModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> sortByLastModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.desc);
    });
  }
}

extension CacheEntryQuerySortThenBy
    on QueryBuilder<CacheEntry, CacheEntry, QSortThenBy> {
  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByEtag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etag', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByEtagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'etag', Sort.desc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByExpiry() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiry', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByExpiryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiry', Sort.desc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByLastModified() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.asc);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QAfterSortBy> thenByLastModifiedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastModified', Sort.desc);
    });
  }
}

extension CacheEntryQueryWhereDistinct
    on QueryBuilder<CacheEntry, CacheEntry, QDistinct> {
  QueryBuilder<CacheEntry, CacheEntry, QDistinct> distinctByBodyBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyBytes');
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QDistinct> distinctByEtag({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'etag', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QDistinct> distinctByExpiry() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiry');
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QDistinct> distinctByKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CacheEntry, CacheEntry, QDistinct> distinctByLastModified({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastModified', caseSensitive: caseSensitive);
    });
  }
}

extension CacheEntryQueryProperty
    on QueryBuilder<CacheEntry, CacheEntry, QQueryProperty> {
  QueryBuilder<CacheEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CacheEntry, List<int>, QQueryOperations> bodyBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyBytes');
    });
  }

  QueryBuilder<CacheEntry, String?, QQueryOperations> etagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'etag');
    });
  }

  QueryBuilder<CacheEntry, DateTime, QQueryOperations> expiryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiry');
    });
  }

  QueryBuilder<CacheEntry, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<CacheEntry, String?, QQueryOperations> lastModifiedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastModified');
    });
  }
}
