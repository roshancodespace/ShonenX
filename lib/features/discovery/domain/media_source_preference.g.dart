// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_source_preference.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMediaSourcePreferenceCollection on Isar {
  IsarCollection<MediaSourcePreference> get mediaSourcePreferences =>
      this.collection();
}

const MediaSourcePreferenceSchema = CollectionSchema(
  name: r'MediaSourcePreference',
  id: -7687347840577956678,
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

  estimateSize: _mediaSourcePreferenceEstimateSize,
  serialize: _mediaSourcePreferenceSerialize,
  deserialize: _mediaSourcePreferenceDeserialize,
  deserializeProp: _mediaSourcePreferenceDeserializeProp,
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

  getId: _mediaSourcePreferenceGetId,
  getLinks: _mediaSourcePreferenceGetLinks,
  attach: _mediaSourcePreferenceAttach,
  version: '3.3.0',
);

int _mediaSourcePreferenceEstimateSize(
  MediaSourcePreference object,
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

void _mediaSourcePreferenceSerialize(
  MediaSourcePreference object,
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

MediaSourcePreference _mediaSourcePreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MediaSourcePreference();
  object.id = id;
  object.manualOverrideId = reader.readStringOrNull(offsets[0]);
  object.manualOverrideTitle = reader.readStringOrNull(offsets[1]);
  object.mediaTitle = reader.readString(offsets[2]);
  object.preferredSourceId = reader.readString(offsets[3]);
  object.preferredSourceName = reader.readString(offsets[4]);
  object.preferredSourceType = reader.readString(offsets[5]);
  return object;
}

P _mediaSourcePreferenceDeserializeProp<P>(
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

Id _mediaSourcePreferenceGetId(MediaSourcePreference object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mediaSourcePreferenceGetLinks(
  MediaSourcePreference object,
) {
  return [];
}

void _mediaSourcePreferenceAttach(
  IsarCollection<dynamic> col,
  Id id,
  MediaSourcePreference object,
) {
  object.id = id;
}

extension MediaSourcePreferenceByIndex
    on IsarCollection<MediaSourcePreference> {
  Future<MediaSourcePreference?> getByMediaTitle(String mediaTitle) {
    return getByIndex(r'mediaTitle', [mediaTitle]);
  }

  MediaSourcePreference? getByMediaTitleSync(String mediaTitle) {
    return getByIndexSync(r'mediaTitle', [mediaTitle]);
  }

  Future<bool> deleteByMediaTitle(String mediaTitle) {
    return deleteByIndex(r'mediaTitle', [mediaTitle]);
  }

  bool deleteByMediaTitleSync(String mediaTitle) {
    return deleteByIndexSync(r'mediaTitle', [mediaTitle]);
  }

  Future<List<MediaSourcePreference?>> getAllByMediaTitle(
    List<String> mediaTitleValues,
  ) {
    final values = mediaTitleValues.map((e) => [e]).toList();
    return getAllByIndex(r'mediaTitle', values);
  }

  List<MediaSourcePreference?> getAllByMediaTitleSync(
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

  Future<Id> putByMediaTitle(MediaSourcePreference object) {
    return putByIndex(r'mediaTitle', object);
  }

  Id putByMediaTitleSync(
    MediaSourcePreference object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'mediaTitle', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMediaTitle(List<MediaSourcePreference> objects) {
    return putAllByIndex(r'mediaTitle', objects);
  }

  List<Id> putAllByMediaTitleSync(
    List<MediaSourcePreference> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'mediaTitle', objects, saveLinks: saveLinks);
  }
}

extension MediaSourcePreferenceQueryWhereSort
    on QueryBuilder<MediaSourcePreference, MediaSourcePreference, QWhere> {
  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MediaSourcePreferenceQueryWhere
    on
        QueryBuilder<
          MediaSourcePreference,
          MediaSourcePreference,
          QWhereClause
        > {
  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhereClause>
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

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhereClause>
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

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhereClause>
  mediaTitleEqualTo(String mediaTitle) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'mediaTitle', value: [mediaTitle]),
      );
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterWhereClause>
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

extension MediaSourcePreferenceQueryFilter
    on
        QueryBuilder<
          MediaSourcePreference,
          MediaSourcePreference,
          QFilterCondition
        > {
  QueryBuilder<
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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
    MediaSourcePreference,
    MediaSourcePreference,
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

extension MediaSourcePreferenceQueryObject
    on
        QueryBuilder<
          MediaSourcePreference,
          MediaSourcePreference,
          QFilterCondition
        > {}

extension MediaSourcePreferenceQueryLinks
    on
        QueryBuilder<
          MediaSourcePreference,
          MediaSourcePreference,
          QFilterCondition
        > {}

extension MediaSourcePreferenceQuerySortBy
    on QueryBuilder<MediaSourcePreference, MediaSourcePreference, QSortBy> {
  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByManualOverrideId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByManualOverrideIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByManualOverrideTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByManualOverrideTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByPreferredSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByPreferredSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByPreferredSourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByPreferredSourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByPreferredSourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  sortByPreferredSourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.desc);
    });
  }
}

extension MediaSourcePreferenceQuerySortThenBy
    on QueryBuilder<MediaSourcePreference, MediaSourcePreference, QSortThenBy> {
  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByManualOverrideId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByManualOverrideIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByManualOverrideTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByManualOverrideTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByPreferredSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByPreferredSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByPreferredSourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByPreferredSourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.desc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByPreferredSourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.asc);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QAfterSortBy>
  thenByPreferredSourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.desc);
    });
  }
}

extension MediaSourcePreferenceQueryWhereDistinct
    on QueryBuilder<MediaSourcePreference, MediaSourcePreference, QDistinct> {
  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QDistinct>
  distinctByManualOverrideId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manualOverrideId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QDistinct>
  distinctByManualOverrideTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manualOverrideTitle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QDistinct>
  distinctByMediaTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QDistinct>
  distinctByPreferredSourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QDistinct>
  distinctByPreferredSourceName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaSourcePreference, MediaSourcePreference, QDistinct>
  distinctByPreferredSourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceType',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension MediaSourcePreferenceQueryProperty
    on
        QueryBuilder<
          MediaSourcePreference,
          MediaSourcePreference,
          QQueryProperty
        > {
  QueryBuilder<MediaSourcePreference, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MediaSourcePreference, String?, QQueryOperations>
  manualOverrideIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualOverrideId');
    });
  }

  QueryBuilder<MediaSourcePreference, String?, QQueryOperations>
  manualOverrideTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualOverrideTitle');
    });
  }

  QueryBuilder<MediaSourcePreference, String, QQueryOperations>
  mediaTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaTitle');
    });
  }

  QueryBuilder<MediaSourcePreference, String, QQueryOperations>
  preferredSourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceId');
    });
  }

  QueryBuilder<MediaSourcePreference, String, QQueryOperations>
  preferredSourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceName');
    });
  }

  QueryBuilder<MediaSourcePreference, String, QQueryOperations>
  preferredSourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceType');
    });
  }
}
