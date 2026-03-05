// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_source_preference.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarSourcePreferenceCollection on Isar {
  IsarCollection<IsarSourcePreference> get isarSourcePreferences =>
      this.collection();
}

const IsarSourcePreferenceSchema = CollectionSchema(
  name: r'IsarSourcePreference',
  id: 8557062117057454834,
  properties: {
    r'animeCover': PropertySchema(
      id: 0,
      name: r'animeCover',
      type: IsarType.string,
    ),
    r'animeId': PropertySchema(id: 1, name: r'animeId', type: IsarType.string),
    r'matchedAnimeId': PropertySchema(
      id: 2,
      name: r'matchedAnimeId',
      type: IsarType.string,
    ),
    r'matchedAnimeTitle': PropertySchema(
      id: 3,
      name: r'matchedAnimeTitle',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 4,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'sourceType': PropertySchema(
      id: 5,
      name: r'sourceType',
      type: IsarType.string,
    ),
  },

  estimateSize: _isarSourcePreferenceEstimateSize,
  serialize: _isarSourcePreferenceSerialize,
  deserialize: _isarSourcePreferenceDeserialize,
  deserializeProp: _isarSourcePreferenceDeserializeProp,
  idName: r'id',
  indexes: {
    r'animeId': IndexSchema(
      id: 4402861282981058668,
      name: r'animeId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'animeId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarSourcePreferenceGetId,
  getLinks: _isarSourcePreferenceGetLinks,
  attach: _isarSourcePreferenceAttach,
  version: '3.3.0',
);

int _isarSourcePreferenceEstimateSize(
  IsarSourcePreference object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.animeCover;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.animeId.length * 3;
  {
    final value = object.matchedAnimeId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.matchedAnimeTitle;
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
    final value = object.sourceType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _isarSourcePreferenceSerialize(
  IsarSourcePreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.animeCover);
  writer.writeString(offsets[1], object.animeId);
  writer.writeString(offsets[2], object.matchedAnimeId);
  writer.writeString(offsets[3], object.matchedAnimeTitle);
  writer.writeString(offsets[4], object.sourceId);
  writer.writeString(offsets[5], object.sourceType);
}

IsarSourcePreference _isarSourcePreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSourcePreference(
    animeCover: reader.readStringOrNull(offsets[0]),
    animeId: reader.readString(offsets[1]),
    id: id,
    matchedAnimeId: reader.readStringOrNull(offsets[2]),
    matchedAnimeTitle: reader.readStringOrNull(offsets[3]),
    sourceId: reader.readStringOrNull(offsets[4]),
    sourceType: reader.readStringOrNull(offsets[5]),
  );
  return object;
}

P _isarSourcePreferenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSourcePreferenceGetId(IsarSourcePreference object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _isarSourcePreferenceGetLinks(
  IsarSourcePreference object,
) {
  return [];
}

void _isarSourcePreferenceAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarSourcePreference object,
) {
  object.id = id;
}

extension IsarSourcePreferenceByIndex on IsarCollection<IsarSourcePreference> {
  Future<IsarSourcePreference?> getByAnimeId(String animeId) {
    return getByIndex(r'animeId', [animeId]);
  }

  IsarSourcePreference? getByAnimeIdSync(String animeId) {
    return getByIndexSync(r'animeId', [animeId]);
  }

  Future<bool> deleteByAnimeId(String animeId) {
    return deleteByIndex(r'animeId', [animeId]);
  }

  bool deleteByAnimeIdSync(String animeId) {
    return deleteByIndexSync(r'animeId', [animeId]);
  }

  Future<List<IsarSourcePreference?>> getAllByAnimeId(
    List<String> animeIdValues,
  ) {
    final values = animeIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'animeId', values);
  }

  List<IsarSourcePreference?> getAllByAnimeIdSync(List<String> animeIdValues) {
    final values = animeIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'animeId', values);
  }

  Future<int> deleteAllByAnimeId(List<String> animeIdValues) {
    final values = animeIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'animeId', values);
  }

  int deleteAllByAnimeIdSync(List<String> animeIdValues) {
    final values = animeIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'animeId', values);
  }

  Future<Id> putByAnimeId(IsarSourcePreference object) {
    return putByIndex(r'animeId', object);
  }

  Id putByAnimeIdSync(IsarSourcePreference object, {bool saveLinks = true}) {
    return putByIndexSync(r'animeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAnimeId(List<IsarSourcePreference> objects) {
    return putAllByIndex(r'animeId', objects);
  }

  List<Id> putAllByAnimeIdSync(
    List<IsarSourcePreference> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'animeId', objects, saveLinks: saveLinks);
  }
}

extension IsarSourcePreferenceQueryWhereSort
    on QueryBuilder<IsarSourcePreference, IsarSourcePreference, QWhere> {
  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarSourcePreferenceQueryWhere
    on QueryBuilder<IsarSourcePreference, IsarSourcePreference, QWhereClause> {
  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
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

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
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

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
  animeIdEqualTo(String animeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'animeId', value: [animeId]),
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
  animeIdNotEqualTo(String animeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'animeId',
                lower: [],
                upper: [animeId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'animeId',
                lower: [animeId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'animeId',
                lower: [animeId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'animeId',
                lower: [],
                upper: [animeId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarSourcePreferenceQueryFilter
    on
        QueryBuilder<
          IsarSourcePreference,
          IsarSourcePreference,
          QFilterCondition
        > {
  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'animeCover'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'animeCover'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'animeCover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'animeCover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'animeCover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'animeCover',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'animeCover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'animeCover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'animeCover',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'animeCover',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'animeCover', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeCoverIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'animeCover', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'animeId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  animeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'animeId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'id'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'id'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  idGreaterThan(Id? value, {bool include = false}) {
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  idLessThan(Id? value, {bool include = false}) {
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  idBetween(
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'matchedAnimeId'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'matchedAnimeId'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'matchedAnimeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchedAnimeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchedAnimeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchedAnimeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'matchedAnimeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'matchedAnimeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'matchedAnimeId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'matchedAnimeId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchedAnimeId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchedAnimeId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'matchedAnimeTitle'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'matchedAnimeTitle'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'matchedAnimeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'matchedAnimeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'matchedAnimeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'matchedAnimeTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'matchedAnimeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'matchedAnimeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'matchedAnimeTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'matchedAnimeTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchedAnimeTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  matchedAnimeTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchedAnimeTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceType'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceType'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceType', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  sourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceType', value: ''),
      );
    });
  }
}

extension IsarSourcePreferenceQueryObject
    on
        QueryBuilder<
          IsarSourcePreference,
          IsarSourcePreference,
          QFilterCondition
        > {}

extension IsarSourcePreferenceQueryLinks
    on
        QueryBuilder<
          IsarSourcePreference,
          IsarSourcePreference,
          QFilterCondition
        > {}

extension IsarSourcePreferenceQuerySortBy
    on QueryBuilder<IsarSourcePreference, IsarSourcePreference, QSortBy> {
  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByAnimeCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByAnimeCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByMatchedAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByMatchedAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByMatchedAnimeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByMatchedAnimeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }
}

extension IsarSourcePreferenceQuerySortThenBy
    on QueryBuilder<IsarSourcePreference, IsarSourcePreference, QSortThenBy> {
  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByAnimeCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByAnimeCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByMatchedAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByMatchedAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByMatchedAnimeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByMatchedAnimeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'matchedAnimeTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenBySourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenBySourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceType', Sort.desc);
    });
  }
}

extension IsarSourcePreferenceQueryWhereDistinct
    on QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct> {
  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByAnimeCover({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeCover', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByAnimeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByMatchedAnimeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'matchedAnimeId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByMatchedAnimeTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'matchedAnimeTitle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctBySourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctBySourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceType', caseSensitive: caseSensitive);
    });
  }
}

extension IsarSourcePreferenceQueryProperty
    on
        QueryBuilder<
          IsarSourcePreference,
          IsarSourcePreference,
          QQueryProperty
        > {
  QueryBuilder<IsarSourcePreference, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarSourcePreference, String?, QQueryOperations>
  animeCoverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeCover');
    });
  }

  QueryBuilder<IsarSourcePreference, String, QQueryOperations>
  animeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeId');
    });
  }

  QueryBuilder<IsarSourcePreference, String?, QQueryOperations>
  matchedAnimeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchedAnimeId');
    });
  }

  QueryBuilder<IsarSourcePreference, String?, QQueryOperations>
  matchedAnimeTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'matchedAnimeTitle');
    });
  }

  QueryBuilder<IsarSourcePreference, String?, QQueryOperations>
  sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<IsarSourcePreference, String?, QQueryOperations>
  sourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceType');
    });
  }
}
