// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_preference.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMediaPreferenceCollection on Isar {
  IsarCollection<MediaPreference> get mediaPreferences => this.collection();
}

const MediaPreferenceSchema = CollectionSchema(
  name: r'MediaPreference',
  id: 916434586304258480,
  properties: {
    r'manualAiringTrackerId': PropertySchema(
      id: 0,
      name: r'manualAiringTrackerId',
      type: IsarType.string,
    ),
    r'manualOverrideId': PropertySchema(
      id: 1,
      name: r'manualOverrideId',
      type: IsarType.string,
    ),
    r'manualOverrideTitle': PropertySchema(
      id: 2,
      name: r'manualOverrideTitle',
      type: IsarType.string,
    ),
    r'mediaTitle': PropertySchema(
      id: 3,
      name: r'mediaTitle',
      type: IsarType.string,
    ),
    r'preferredAiringTracker': PropertySchema(
      id: 4,
      name: r'preferredAiringTracker',
      type: IsarType.string,
    ),
    r'preferredSourceId': PropertySchema(
      id: 5,
      name: r'preferredSourceId',
      type: IsarType.string,
    ),
    r'preferredSourceName': PropertySchema(
      id: 6,
      name: r'preferredSourceName',
      type: IsarType.string,
    ),
    r'preferredSourceType': PropertySchema(
      id: 7,
      name: r'preferredSourceType',
      type: IsarType.string,
    ),
  },

  estimateSize: _mediaPreferenceEstimateSize,
  serialize: _mediaPreferenceSerialize,
  deserialize: _mediaPreferenceDeserialize,
  deserializeProp: _mediaPreferenceDeserializeProp,
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

  getId: _mediaPreferenceGetId,
  getLinks: _mediaPreferenceGetLinks,
  attach: _mediaPreferenceAttach,
  version: '3.3.0',
);

int _mediaPreferenceEstimateSize(
  MediaPreference object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.manualAiringTrackerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  {
    final value = object.preferredAiringTracker;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.preferredSourceId.length * 3;
  bytesCount += 3 + object.preferredSourceName.length * 3;
  bytesCount += 3 + object.preferredSourceType.length * 3;
  return bytesCount;
}

void _mediaPreferenceSerialize(
  MediaPreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.manualAiringTrackerId);
  writer.writeString(offsets[1], object.manualOverrideId);
  writer.writeString(offsets[2], object.manualOverrideTitle);
  writer.writeString(offsets[3], object.mediaTitle);
  writer.writeString(offsets[4], object.preferredAiringTracker);
  writer.writeString(offsets[5], object.preferredSourceId);
  writer.writeString(offsets[6], object.preferredSourceName);
  writer.writeString(offsets[7], object.preferredSourceType);
}

MediaPreference _mediaPreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MediaPreference();
  object.id = id;
  object.manualAiringTrackerId = reader.readStringOrNull(offsets[0]);
  object.manualOverrideId = reader.readStringOrNull(offsets[1]);
  object.manualOverrideTitle = reader.readStringOrNull(offsets[2]);
  object.mediaTitle = reader.readString(offsets[3]);
  object.preferredAiringTracker = reader.readStringOrNull(offsets[4]);
  object.preferredSourceId = reader.readString(offsets[5]);
  object.preferredSourceName = reader.readString(offsets[6]);
  object.preferredSourceType = reader.readString(offsets[7]);
  return object;
}

P _mediaPreferenceDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _mediaPreferenceGetId(MediaPreference object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _mediaPreferenceGetLinks(MediaPreference object) {
  return [];
}

void _mediaPreferenceAttach(
  IsarCollection<dynamic> col,
  Id id,
  MediaPreference object,
) {
  object.id = id;
}

extension MediaPreferenceByIndex on IsarCollection<MediaPreference> {
  Future<MediaPreference?> getByMediaTitle(String mediaTitle) {
    return getByIndex(r'mediaTitle', [mediaTitle]);
  }

  MediaPreference? getByMediaTitleSync(String mediaTitle) {
    return getByIndexSync(r'mediaTitle', [mediaTitle]);
  }

  Future<bool> deleteByMediaTitle(String mediaTitle) {
    return deleteByIndex(r'mediaTitle', [mediaTitle]);
  }

  bool deleteByMediaTitleSync(String mediaTitle) {
    return deleteByIndexSync(r'mediaTitle', [mediaTitle]);
  }

  Future<List<MediaPreference?>> getAllByMediaTitle(
    List<String> mediaTitleValues,
  ) {
    final values = mediaTitleValues.map((e) => [e]).toList();
    return getAllByIndex(r'mediaTitle', values);
  }

  List<MediaPreference?> getAllByMediaTitleSync(List<String> mediaTitleValues) {
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

  Future<Id> putByMediaTitle(MediaPreference object) {
    return putByIndex(r'mediaTitle', object);
  }

  Id putByMediaTitleSync(MediaPreference object, {bool saveLinks = true}) {
    return putByIndexSync(r'mediaTitle', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMediaTitle(List<MediaPreference> objects) {
    return putAllByIndex(r'mediaTitle', objects);
  }

  List<Id> putAllByMediaTitleSync(
    List<MediaPreference> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'mediaTitle', objects, saveLinks: saveLinks);
  }
}

extension MediaPreferenceQueryWhereSort
    on QueryBuilder<MediaPreference, MediaPreference, QWhere> {
  QueryBuilder<MediaPreference, MediaPreference, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MediaPreferenceQueryWhere
    on QueryBuilder<MediaPreference, MediaPreference, QWhereClause> {
  QueryBuilder<MediaPreference, MediaPreference, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterWhereClause>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterWhereClause> idBetween(
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterWhereClause>
  mediaTitleEqualTo(String mediaTitle) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'mediaTitle', value: [mediaTitle]),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterWhereClause>
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

extension MediaPreferenceQueryFilter
    on QueryBuilder<MediaPreference, MediaPreference, QFilterCondition> {
  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manualAiringTrackerId'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manualAiringTrackerId'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'manualAiringTrackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'manualAiringTrackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'manualAiringTrackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'manualAiringTrackerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'manualAiringTrackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'manualAiringTrackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'manualAiringTrackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'manualAiringTrackerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manualAiringTrackerId', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualAiringTrackerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'manualAiringTrackerId',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualOverrideIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manualOverrideId'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualOverrideIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manualOverrideId'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualOverrideIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manualOverrideId', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualOverrideIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'manualOverrideId', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualOverrideTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'manualOverrideTitle'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualOverrideTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'manualOverrideTitle'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  manualOverrideTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'manualOverrideTitle', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  mediaTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mediaTitle', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  mediaTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mediaTitle', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'preferredAiringTracker'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'preferredAiringTracker'),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'preferredAiringTracker',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'preferredAiringTracker',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'preferredAiringTracker',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'preferredAiringTracker',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'preferredAiringTracker',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'preferredAiringTracker',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'preferredAiringTracker',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'preferredAiringTracker',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferredAiringTracker', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredAiringTrackerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'preferredAiringTracker',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredSourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferredSourceId', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredSourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'preferredSourceId', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredSourceNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferredSourceName', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
  preferredSourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'preferredSourceType', value: ''),
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterFilterCondition>
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

extension MediaPreferenceQueryObject
    on QueryBuilder<MediaPreference, MediaPreference, QFilterCondition> {}

extension MediaPreferenceQueryLinks
    on QueryBuilder<MediaPreference, MediaPreference, QFilterCondition> {}

extension MediaPreferenceQuerySortBy
    on QueryBuilder<MediaPreference, MediaPreference, QSortBy> {
  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByManualAiringTrackerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualAiringTrackerId', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByManualAiringTrackerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualAiringTrackerId', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByManualOverrideId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByManualOverrideIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByManualOverrideTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByManualOverrideTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredAiringTracker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAiringTracker', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredAiringTrackerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAiringTracker', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredSourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredSourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredSourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  sortByPreferredSourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.desc);
    });
  }
}

extension MediaPreferenceQuerySortThenBy
    on QueryBuilder<MediaPreference, MediaPreference, QSortThenBy> {
  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByManualAiringTrackerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualAiringTrackerId', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByManualAiringTrackerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualAiringTrackerId', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByManualOverrideId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByManualOverrideIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideId', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByManualOverrideTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByManualOverrideTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'manualOverrideTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByMediaTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByMediaTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mediaTitle', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredAiringTracker() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAiringTracker', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredAiringTrackerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredAiringTracker', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredSourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredSourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceId', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredSourceName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredSourceNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceName', Sort.desc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredSourceType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.asc);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QAfterSortBy>
  thenByPreferredSourceTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredSourceType', Sort.desc);
    });
  }
}

extension MediaPreferenceQueryWhereDistinct
    on QueryBuilder<MediaPreference, MediaPreference, QDistinct> {
  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByManualAiringTrackerId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manualAiringTrackerId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByManualOverrideId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manualOverrideId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByManualOverrideTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'manualOverrideTitle',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByMediaTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mediaTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByPreferredAiringTracker({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredAiringTracker',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByPreferredSourceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByPreferredSourceName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<MediaPreference, MediaPreference, QDistinct>
  distinctByPreferredSourceType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'preferredSourceType',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension MediaPreferenceQueryProperty
    on QueryBuilder<MediaPreference, MediaPreference, QQueryProperty> {
  QueryBuilder<MediaPreference, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MediaPreference, String?, QQueryOperations>
  manualAiringTrackerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualAiringTrackerId');
    });
  }

  QueryBuilder<MediaPreference, String?, QQueryOperations>
  manualOverrideIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualOverrideId');
    });
  }

  QueryBuilder<MediaPreference, String?, QQueryOperations>
  manualOverrideTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manualOverrideTitle');
    });
  }

  QueryBuilder<MediaPreference, String, QQueryOperations> mediaTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mediaTitle');
    });
  }

  QueryBuilder<MediaPreference, String?, QQueryOperations>
  preferredAiringTrackerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredAiringTracker');
    });
  }

  QueryBuilder<MediaPreference, String, QQueryOperations>
  preferredSourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceId');
    });
  }

  QueryBuilder<MediaPreference, String, QQueryOperations>
  preferredSourceNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceName');
    });
  }

  QueryBuilder<MediaPreference, String, QQueryOperations>
  preferredSourceTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredSourceType');
    });
  }
}
