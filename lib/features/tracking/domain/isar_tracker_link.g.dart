// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_tracker_link.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarTrackerLinkCollection on Isar {
  IsarCollection<IsarTrackerLink> get isarTrackerLinks => this.collection();
}

const IsarTrackerLinkSchema = CollectionSchema(
  name: r'IsarTrackerLink',
  id: -1549271986729188444,
  properties: {
    r'mappings': PropertySchema(
      id: 0,
      name: r'mappings',
      type: IsarType.objectList,

      target: r'TrackerMapping',
    ),
    r'primaryMediaId': PropertySchema(
      id: 1,
      name: r'primaryMediaId',
      type: IsarType.string,
    ),
  },

  estimateSize: _isarTrackerLinkEstimateSize,
  serialize: _isarTrackerLinkSerialize,
  deserialize: _isarTrackerLinkDeserialize,
  deserializeProp: _isarTrackerLinkDeserializeProp,
  idName: r'id',
  indexes: {
    r'primaryMediaId': IndexSchema(
      id: 3689626557092764249,
      name: r'primaryMediaId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'primaryMediaId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {r'TrackerMapping': TrackerMappingSchema},

  getId: _isarTrackerLinkGetId,
  getLinks: _isarTrackerLinkGetLinks,
  attach: _isarTrackerLinkAttach,
  version: '3.3.0',
);

int _isarTrackerLinkEstimateSize(
  IsarTrackerLink object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.mappings.length * 3;
  {
    final offsets = allOffsets[TrackerMapping]!;
    for (var i = 0; i < object.mappings.length; i++) {
      final value = object.mappings[i];
      bytesCount += TrackerMappingSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  bytesCount += 3 + object.primaryMediaId.length * 3;
  return bytesCount;
}

void _isarTrackerLinkSerialize(
  IsarTrackerLink object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<TrackerMapping>(
    offsets[0],
    allOffsets,
    TrackerMappingSchema.serialize,
    object.mappings,
  );
  writer.writeString(offsets[1], object.primaryMediaId);
}

IsarTrackerLink _isarTrackerLinkDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarTrackerLink();
  object.id = id;
  object.mappings =
      reader.readObjectList<TrackerMapping>(
        offsets[0],
        TrackerMappingSchema.deserialize,
        allOffsets,
        TrackerMapping(),
      ) ??
      [];
  object.primaryMediaId = reader.readString(offsets[1]);
  return object;
}

P _isarTrackerLinkDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<TrackerMapping>(
                offset,
                TrackerMappingSchema.deserialize,
                allOffsets,
                TrackerMapping(),
              ) ??
              [])
          as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarTrackerLinkGetId(IsarTrackerLink object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarTrackerLinkGetLinks(IsarTrackerLink object) {
  return [];
}

void _isarTrackerLinkAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarTrackerLink object,
) {
  object.id = id;
}

extension IsarTrackerLinkByIndex on IsarCollection<IsarTrackerLink> {
  Future<IsarTrackerLink?> getByPrimaryMediaId(String primaryMediaId) {
    return getByIndex(r'primaryMediaId', [primaryMediaId]);
  }

  IsarTrackerLink? getByPrimaryMediaIdSync(String primaryMediaId) {
    return getByIndexSync(r'primaryMediaId', [primaryMediaId]);
  }

  Future<bool> deleteByPrimaryMediaId(String primaryMediaId) {
    return deleteByIndex(r'primaryMediaId', [primaryMediaId]);
  }

  bool deleteByPrimaryMediaIdSync(String primaryMediaId) {
    return deleteByIndexSync(r'primaryMediaId', [primaryMediaId]);
  }

  Future<List<IsarTrackerLink?>> getAllByPrimaryMediaId(
    List<String> primaryMediaIdValues,
  ) {
    final values = primaryMediaIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'primaryMediaId', values);
  }

  List<IsarTrackerLink?> getAllByPrimaryMediaIdSync(
    List<String> primaryMediaIdValues,
  ) {
    final values = primaryMediaIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'primaryMediaId', values);
  }

  Future<int> deleteAllByPrimaryMediaId(List<String> primaryMediaIdValues) {
    final values = primaryMediaIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'primaryMediaId', values);
  }

  int deleteAllByPrimaryMediaIdSync(List<String> primaryMediaIdValues) {
    final values = primaryMediaIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'primaryMediaId', values);
  }

  Future<Id> putByPrimaryMediaId(IsarTrackerLink object) {
    return putByIndex(r'primaryMediaId', object);
  }

  Id putByPrimaryMediaIdSync(IsarTrackerLink object, {bool saveLinks = true}) {
    return putByIndexSync(r'primaryMediaId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPrimaryMediaId(List<IsarTrackerLink> objects) {
    return putAllByIndex(r'primaryMediaId', objects);
  }

  List<Id> putAllByPrimaryMediaIdSync(
    List<IsarTrackerLink> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'primaryMediaId', objects, saveLinks: saveLinks);
  }
}

extension IsarTrackerLinkQueryWhereSort
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QWhere> {
  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarTrackerLinkQueryWhere
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QWhereClause> {
  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhereClause>
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

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhereClause> idBetween(
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

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhereClause>
  primaryMediaIdEqualTo(String primaryMediaId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'primaryMediaId',
          value: [primaryMediaId],
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterWhereClause>
  primaryMediaIdNotEqualTo(String primaryMediaId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'primaryMediaId',
                lower: [],
                upper: [primaryMediaId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'primaryMediaId',
                lower: [primaryMediaId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'primaryMediaId',
                lower: [primaryMediaId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'primaryMediaId',
                lower: [],
                upper: [primaryMediaId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarTrackerLinkQueryFilter
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QFilterCondition> {
  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
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

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
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

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
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

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  mappingsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'mappings', length, true, length, true);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  mappingsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'mappings', 0, true, 0, true);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  mappingsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'mappings', 0, false, 999999, true);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  mappingsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'mappings', 0, true, length, include);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  mappingsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'mappings', length, include, 999999, true);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  mappingsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'mappings',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'primaryMediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'primaryMediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'primaryMediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'primaryMediaId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'primaryMediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'primaryMediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'primaryMediaId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'primaryMediaId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'primaryMediaId', value: ''),
      );
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  primaryMediaIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'primaryMediaId', value: ''),
      );
    });
  }
}

extension IsarTrackerLinkQueryObject
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QFilterCondition> {
  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterFilterCondition>
  mappingsElement(FilterQuery<TrackerMapping> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'mappings');
    });
  }
}

extension IsarTrackerLinkQueryLinks
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QFilterCondition> {}

extension IsarTrackerLinkQuerySortBy
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QSortBy> {
  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterSortBy>
  sortByPrimaryMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMediaId', Sort.asc);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterSortBy>
  sortByPrimaryMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMediaId', Sort.desc);
    });
  }
}

extension IsarTrackerLinkQuerySortThenBy
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QSortThenBy> {
  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterSortBy>
  thenByPrimaryMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMediaId', Sort.asc);
    });
  }

  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QAfterSortBy>
  thenByPrimaryMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primaryMediaId', Sort.desc);
    });
  }
}

extension IsarTrackerLinkQueryWhereDistinct
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QDistinct> {
  QueryBuilder<IsarTrackerLink, IsarTrackerLink, QDistinct>
  distinctByPrimaryMediaId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'primaryMediaId',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension IsarTrackerLinkQueryProperty
    on QueryBuilder<IsarTrackerLink, IsarTrackerLink, QQueryProperty> {
  QueryBuilder<IsarTrackerLink, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarTrackerLink, List<TrackerMapping>, QQueryOperations>
  mappingsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mappings');
    });
  }

  QueryBuilder<IsarTrackerLink, String, QQueryOperations>
  primaryMediaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primaryMediaId');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TrackerMappingSchema = Schema(
  name: r'TrackerMapping',
  id: -8838007940405798117,
  properties: {
    r'trackerId': PropertySchema(
      id: 0,
      name: r'trackerId',
      type: IsarType.string,
    ),
    r'trackingId': PropertySchema(
      id: 1,
      name: r'trackingId',
      type: IsarType.string,
    ),
    r'trackingTitle': PropertySchema(
      id: 2,
      name: r'trackingTitle',
      type: IsarType.string,
    ),
  },

  estimateSize: _trackerMappingEstimateSize,
  serialize: _trackerMappingSerialize,
  deserialize: _trackerMappingDeserialize,
  deserializeProp: _trackerMappingDeserializeProp,
);

int _trackerMappingEstimateSize(
  TrackerMapping object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.trackerId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.trackingId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.trackingTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _trackerMappingSerialize(
  TrackerMapping object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.trackerId);
  writer.writeString(offsets[1], object.trackingId);
  writer.writeString(offsets[2], object.trackingTitle);
}

TrackerMapping _trackerMappingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TrackerMapping();
  object.trackerId = reader.readStringOrNull(offsets[0]);
  object.trackingId = reader.readStringOrNull(offsets[1]);
  object.trackingTitle = reader.readStringOrNull(offsets[2]);
  return object;
}

P _trackerMappingDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TrackerMappingQueryFilter
    on QueryBuilder<TrackerMapping, TrackerMapping, QFilterCondition> {
  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trackerId'),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trackerId'),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'trackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'trackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'trackerId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'trackerId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackerId', value: ''),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackerIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'trackerId', value: ''),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trackingId'),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trackingId'),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trackingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackingId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'trackingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'trackingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'trackingId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'trackingId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackingId', value: ''),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'trackingId', value: ''),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trackingTitle'),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trackingTitle'),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trackingTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackingTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackingTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackingTitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'trackingTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'trackingTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'trackingTitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'trackingTitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackingTitle', value: ''),
      );
    });
  }

  QueryBuilder<TrackerMapping, TrackerMapping, QAfterFilterCondition>
  trackingTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'trackingTitle', value: ''),
      );
    });
  }
}

extension TrackerMappingQueryObject
    on QueryBuilder<TrackerMapping, TrackerMapping, QFilterCondition> {}
