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
    r'manualOverrideId': PropertySchema(
      id: 0,
      name: r'manualOverrideId',
      type: IsarType.string,
    ),
    r'manualOverrideTitle': PropertySchema(
      id: 1,
      name: r'manualOverrideTitle',
      type: IsarType.string,
    ),
    r'mediaTitle': PropertySchema(
      id: 2,
      name: r'mediaTitle',
      type: IsarType.string,
    ),
    r'preferredSourceId': PropertySchema(
      id: 3,
      name: r'preferredSourceId',
      type: IsarType.string,
    ),
    r'preferredSourceName': PropertySchema(
      id: 4,
      name: r'preferredSourceName',
      type: IsarType.string,
    ),
    r'preferredSourceType': PropertySchema(
      id: 5,
      name: r'preferredSourceType',
      type: IsarType.string,
    ),
  },

  estimateSize: _isarSourcePreferenceEstimateSize,
  serialize: _isarSourcePreferenceSerialize,
  deserialize: _isarSourcePreferenceDeserialize,
  deserializeProp: _isarSourcePreferenceDeserializeProp,
  idName: r'id',
  indexes: {
    r'mediaTitle': IndexSchema(
      id: 9028852129430095137,
      name: r'mediaTitle',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'mediaTitle',
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
    final value = object.manualOverrideId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.manualOverrideTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mediaTitle.length * 3;
  bytesCount += 3 + object.preferredSourceId.length * 3;
  bytesCount += 3 + object.preferredSourceName.length * 3;
  bytesCount += 3 + object.preferredSourceType.length * 3;
  return bytesCount;
}

void _isarSourcePreferenceSerialize(
  IsarSourcePreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.manualOverrideId);
  writer.writeString(offsets[1], object.manualOverrideTitle);
  writer.writeString(offsets[2], object.mediaTitle);
  writer.writeString(offsets[3], object.preferredSourceId);
  writer.writeString(offsets[4], object.preferredSourceName);
  writer.writeString(offsets[5], object.preferredSourceType);
}

IsarSourcePreference _isarSourcePreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSourcePreference();
  object.id = id;
  object.manualOverrideId = reader.readStringOrNull(offsets[0]);
  object.manualOverrideTitle = reader.readStringOrNull(offsets[1]);
  object.mediaTitle = reader.readString(offsets[2]);
  object.preferredSourceId = reader.readString(offsets[3]);
  object.preferredSourceName = reader.readString(offsets[4]);
  object.preferredSourceType = reader.readString(offsets[5]);
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
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarSourcePreferenceGetId(IsarSourcePreference object) {
  return object.id;
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
  Future<IsarSourcePreference?> getByMediaTitle(String mediaTitle) {
    return getByIndex(r'mediaTitle', [mediaTitle]);
  }

  IsarSourcePreference? getByMediaTitleSync(String mediaTitle) {
    return getByIndexSync(r'mediaTitle', [mediaTitle]);
  }

  Future<bool> deleteByMediaTitle(String mediaTitle) {
    return deleteByIndex(r'mediaTitle', [mediaTitle]);
  }

  bool deleteByMediaTitleSync(String mediaTitle) {
    return deleteByIndexSync(r'mediaTitle', [mediaTitle]);
  }

  Future<List<IsarSourcePreference?>> getAllByMediaTitle(
    List<String> mediaTitleValues,
  ) {
    final values = mediaTitleValues.map((e) => [e]).toList();
    return getAllByIndex(r'mediaTitle', values);
  }

  List<IsarSourcePreference?> getAllByMediaTitleSync(
    List<String> mediaTitleValues,
  ) {
    final values = mediaTitleValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'mediaTitle', values);
  }

  Future<int> deleteAllByMediaTitle(List<String> mediaTitleValues) {
    final values = mediaTitleValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'mediaTitle', values);
  }

  int deleteAllByMediaTitleSync(List<String> mediaTitleValues) {
    final values = mediaTitleValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'mediaTitle', values);
  }

  Future<Id> putByMediaTitle(IsarSourcePreference object) {
    return putByIndex(r'mediaTitle', object);
  }

  Id putByMediaTitleSync(IsarSourcePreference object, {bool saveLinks = true}) {
    return putByIndexSync(r'mediaTitle', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMediaTitle(List<IsarSourcePreference> objects) {
    return putAllByIndex(r'mediaTitle', objects);
  }

  List<Id> putAllByMediaTitleSync(
    List<IsarSourcePreference> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'mediaTitle', objects, saveLinks: saveLinks);
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
  mediaTitleEqualTo(String mediaTitle) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'mediaTitle', value: [mediaTitle]),
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterWhereClause>
  mediaTitleNotEqualTo(String mediaTitle) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaTitle',
                lower: [],
                upper: [mediaTitle],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaTitle',
                lower: [mediaTitle],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaTitle',
                lower: [mediaTitle],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mediaTitle',
                lower: [],
                upper: [mediaTitle],
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
  idEqualTo(Id value) {
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manualOverrideId'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manualOverrideId'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'manualOverrideId',
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
  manualOverrideIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'manualOverrideId',
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
  manualOverrideIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'manualOverrideId',
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
  manualOverrideIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'manualOverrideId',
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
  manualOverrideIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'manualOverrideId',
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
  manualOverrideIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'manualOverrideId',
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
  manualOverrideIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'manualOverrideId',
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
  manualOverrideIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'manualOverrideId',
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
  manualOverrideIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manualOverrideId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'manualOverrideId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manualOverrideTitle'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manualOverrideTitle'),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'manualOverrideTitle',
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
  manualOverrideTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'manualOverrideTitle',
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
  manualOverrideTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'manualOverrideTitle',
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
  manualOverrideTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'manualOverrideTitle',
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
  manualOverrideTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'manualOverrideTitle',
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
  manualOverrideTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'manualOverrideTitle',
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
  manualOverrideTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'manualOverrideTitle',
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
  manualOverrideTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'manualOverrideTitle',
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
  manualOverrideTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manualOverrideTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  manualOverrideTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'manualOverrideTitle',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  mediaTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  mediaTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mediaTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  preferredSourceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'preferredSourceId',
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
  preferredSourceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'preferredSourceId',
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
  preferredSourceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'preferredSourceId',
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
  preferredSourceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'preferredSourceId',
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
  preferredSourceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'preferredSourceId',
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
  preferredSourceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'preferredSourceId',
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
  preferredSourceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'preferredSourceId',
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
  preferredSourceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'preferredSourceId',
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
  preferredSourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferredSourceId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  preferredSourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'preferredSourceId', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  preferredSourceNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'preferredSourceName',
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
  preferredSourceNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'preferredSourceName',
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
  preferredSourceNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'preferredSourceName',
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
  preferredSourceNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'preferredSourceName',
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
  preferredSourceNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'preferredSourceName',
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
  preferredSourceNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'preferredSourceName',
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
  preferredSourceNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'preferredSourceName',
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
  preferredSourceNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'preferredSourceName',
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
  preferredSourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferredSourceName', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  preferredSourceNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'preferredSourceName',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  preferredSourceTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'preferredSourceType',
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
  preferredSourceTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'preferredSourceType',
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
  preferredSourceTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'preferredSourceType',
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
  preferredSourceTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'preferredSourceType',
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
  preferredSourceTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'preferredSourceType',
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
  preferredSourceTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'preferredSourceType',
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
  preferredSourceTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'preferredSourceType',
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
  preferredSourceTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'preferredSourceType',
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
  preferredSourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferredSourceType', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarSourcePreference,
    IsarSourcePreference,
    QAfterFilterCondition
  >
  preferredSourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'preferredSourceType',
          value: '',
        ),
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
  sortByManualOverrideId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByManualOverrideIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByManualOverrideTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByManualOverrideTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByPreferredSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByPreferredSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByPreferredSourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByPreferredSourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByPreferredSourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  sortByPreferredSourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.desc);
    });
  }
}

extension IsarSourcePreferenceQuerySortThenBy
    on QueryBuilder<IsarSourcePreference, IsarSourcePreference, QSortThenBy> {
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
  thenByManualOverrideId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByManualOverrideIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByManualOverrideTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByManualOverrideTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByPreferredSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByPreferredSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByPreferredSourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByPreferredSourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.desc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByPreferredSourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.asc);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QAfterSortBy>
  thenByPreferredSourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.desc);
    });
  }
}

extension IsarSourcePreferenceQueryWhereDistinct
    on QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct> {
  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByManualOverrideId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manualOverrideId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByManualOverrideTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manualOverrideTitle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByMediaTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByPreferredSourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByPreferredSourceName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<IsarSourcePreference, IsarSourcePreference, QDistinct>
  distinctByPreferredSourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceType',
        caseSensitive: caseSensitive,
      );
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
  manualOverrideIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualOverrideId');
    });
  }

  QueryBuilder<IsarSourcePreference, String?, QQueryOperations>
  manualOverrideTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualOverrideTitle');
    });
  }

  QueryBuilder<IsarSourcePreference, String, QQueryOperations>
  mediaTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaTitle');
    });
  }

  QueryBuilder<IsarSourcePreference, String, QQueryOperations>
  preferredSourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceId');
    });
  }

  QueryBuilder<IsarSourcePreference, String, QQueryOperations>
  preferredSourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceName');
    });
  }

  QueryBuilder<IsarSourcePreference, String, QQueryOperations>
  preferredSourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceType');
    });
  }
}
