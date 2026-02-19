// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'external_track_binding.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetExternalTrackBindingCollection on Isar {
  IsarCollection<ExternalTrackBinding> get externalTrackBindings =>
      this.collection();
}

const ExternalTrackBindingSchema = CollectionSchema(
  name: r'ExternalTrackBinding',
  id: -4569922648459673250,
  properties: {
    r'anilistMediaId': PropertySchema(
      id: 0,
      name: r'anilistMediaId',
      type: IsarType.long,
    ),
    r'endDate': PropertySchema(id: 1, name: r'endDate', type: IsarType.long),
    r'startDate': PropertySchema(
      id: 2,
      name: r'startDate',
      type: IsarType.long,
    ),
    r'trackerProgress': PropertySchema(
      id: 3,
      name: r'trackerProgress',
      type: IsarType.long,
    ),
    r'trackerRemoteId': PropertySchema(
      id: 4,
      name: r'trackerRemoteId',
      type: IsarType.long,
    ),
    r'trackerScore': PropertySchema(
      id: 5,
      name: r'trackerScore',
      type: IsarType.double,
    ),
    r'trackerStatus': PropertySchema(
      id: 6,
      name: r'trackerStatus',
      type: IsarType.string,
    ),
    r'trackerType': PropertySchema(
      id: 7,
      name: r'trackerType',
      type: IsarType.byte,
      enumMap: _ExternalTrackBindingtrackerTypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.long,
    ),
  },

  estimateSize: _externalTrackBindingEstimateSize,
  serialize: _externalTrackBindingSerialize,
  deserialize: _externalTrackBindingDeserialize,
  deserializeProp: _externalTrackBindingDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _externalTrackBindingGetId,
  getLinks: _externalTrackBindingGetLinks,
  attach: _externalTrackBindingAttach,
  version: '3.3.0',
);

int _externalTrackBindingEstimateSize(
  ExternalTrackBinding object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.trackerStatus;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _externalTrackBindingSerialize(
  ExternalTrackBinding object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.anilistMediaId);
  writer.writeLong(offsets[1], object.endDate);
  writer.writeLong(offsets[2], object.startDate);
  writer.writeLong(offsets[3], object.trackerProgress);
  writer.writeLong(offsets[4], object.trackerRemoteId);
  writer.writeDouble(offsets[5], object.trackerScore);
  writer.writeString(offsets[6], object.trackerStatus);
  writer.writeByte(offsets[7], object.trackerType.index);
  writer.writeLong(offsets[8], object.updatedAt);
}

ExternalTrackBinding _externalTrackBindingDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExternalTrackBinding(
    anilistMediaId: reader.readLongOrNull(offsets[0]),
    endDate: reader.readLongOrNull(offsets[1]),
    id: id,
    startDate: reader.readLongOrNull(offsets[2]),
    trackerProgress: reader.readLongOrNull(offsets[3]),
    trackerRemoteId: reader.readLongOrNull(offsets[4]),
    trackerScore: reader.readDoubleOrNull(offsets[5]),
    trackerStatus: reader.readStringOrNull(offsets[6]),
    trackerType:
        _ExternalTrackBindingtrackerTypeValueEnumMap[reader.readByteOrNull(
          offsets[7],
        )] ??
        TrackerType.anilist,
    updatedAt: reader.readLongOrNull(offsets[8]),
  );
  return object;
}

P _externalTrackBindingDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (_ExternalTrackBindingtrackerTypeValueEnumMap[reader
                  .readByteOrNull(offset)] ??
              TrackerType.anilist)
          as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ExternalTrackBindingtrackerTypeEnumValueMap = {'anilist': 0, 'mal': 1};
const _ExternalTrackBindingtrackerTypeValueEnumMap = {
  0: TrackerType.anilist,
  1: TrackerType.mal,
};

Id _externalTrackBindingGetId(ExternalTrackBinding object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _externalTrackBindingGetLinks(
  ExternalTrackBinding object,
) {
  return [];
}

void _externalTrackBindingAttach(
  IsarCollection<dynamic> col,
  Id id,
  ExternalTrackBinding object,
) {
  object.id = id;
}

extension ExternalTrackBindingQueryWhereSort
    on QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QWhere> {
  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ExternalTrackBindingQueryWhere
    on QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QWhereClause> {
  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterWhereClause>
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

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterWhereClause>
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
}

extension ExternalTrackBindingQueryFilter
    on
        QueryBuilder<
          ExternalTrackBinding,
          ExternalTrackBinding,
          QFilterCondition
        > {
  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  anilistMediaIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'anilistMediaId'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  anilistMediaIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'anilistMediaId'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  anilistMediaIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'anilistMediaId', value: value),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  anilistMediaIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'anilistMediaId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  anilistMediaIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'anilistMediaId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  anilistMediaIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'anilistMediaId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'endDate'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'endDate'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  endDateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endDate', value: value),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  endDateGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  endDateLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  endDateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
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
    ExternalTrackBinding,
    ExternalTrackBinding,
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
    ExternalTrackBinding,
    ExternalTrackBinding,
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
    ExternalTrackBinding,
    ExternalTrackBinding,
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
    ExternalTrackBinding,
    ExternalTrackBinding,
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
    ExternalTrackBinding,
    ExternalTrackBinding,
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
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'startDate'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'startDate'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  startDateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startDate', value: value),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  startDateGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  startDateLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startDate',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  startDateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startDate',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerProgressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trackerProgress'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerProgressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trackerProgress'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerProgressEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackerProgress', value: value),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerProgressGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackerProgress',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerProgressLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackerProgress',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerProgressBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackerProgress',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerRemoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trackerRemoteId'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerRemoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trackerRemoteId'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerRemoteIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackerRemoteId', value: value),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerRemoteIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackerRemoteId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerRemoteIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackerRemoteId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerRemoteIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackerRemoteId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trackerScore'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trackerScore'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerScoreEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trackerScore',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerScoreGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackerScore',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerScoreLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackerScore',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerScoreBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackerScore',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'trackerStatus'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'trackerStatus'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trackerStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackerStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackerStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackerStatus',
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
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'trackerStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'trackerStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'trackerStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'trackerStatus',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackerStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'trackerStatus', value: ''),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerTypeEqualTo(TrackerType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackerType', value: value),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerTypeGreaterThan(TrackerType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackerType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerTypeLessThan(TrackerType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackerType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  trackerTypeBetween(
    TrackerType lower,
    TrackerType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackerType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  updatedAtEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  updatedAtLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    ExternalTrackBinding,
    ExternalTrackBinding,
    QAfterFilterCondition
  >
  updatedAtBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ExternalTrackBindingQueryObject
    on
        QueryBuilder<
          ExternalTrackBinding,
          ExternalTrackBinding,
          QFilterCondition
        > {}

extension ExternalTrackBindingQueryLinks
    on
        QueryBuilder<
          ExternalTrackBinding,
          ExternalTrackBinding,
          QFilterCondition
        > {}

extension ExternalTrackBindingQuerySortBy
    on QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QSortBy> {
  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByAnilistMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByAnilistMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerProgress', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerProgress', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerRemoteId', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerRemoteId', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerScore', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerScore', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerStatus', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerStatus', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerType', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByTrackerTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerType', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ExternalTrackBindingQuerySortThenBy
    on QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QSortThenBy> {
  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByAnilistMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByAnilistMediaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'anilistMediaId', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'endDate', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerProgress', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerProgress', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerRemoteId', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerRemoteId', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerScore', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerScore', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerStatus', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerStatus', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerType', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByTrackerTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackerType', Sort.desc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ExternalTrackBindingQueryWhereDistinct
    on QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct> {
  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByAnilistMediaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'anilistMediaId');
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'endDate');
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByTrackerProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackerProgress');
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByTrackerRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackerRemoteId');
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByTrackerScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackerScore');
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByTrackerStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'trackerStatus',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByTrackerType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trackerType');
    });
  }

  QueryBuilder<ExternalTrackBinding, ExternalTrackBinding, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ExternalTrackBindingQueryProperty
    on
        QueryBuilder<
          ExternalTrackBinding,
          ExternalTrackBinding,
          QQueryProperty
        > {
  QueryBuilder<ExternalTrackBinding, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ExternalTrackBinding, int?, QQueryOperations>
  anilistMediaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'anilistMediaId');
    });
  }

  QueryBuilder<ExternalTrackBinding, int?, QQueryOperations> endDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'endDate');
    });
  }

  QueryBuilder<ExternalTrackBinding, int?, QQueryOperations>
  startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<ExternalTrackBinding, int?, QQueryOperations>
  trackerProgressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackerProgress');
    });
  }

  QueryBuilder<ExternalTrackBinding, int?, QQueryOperations>
  trackerRemoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackerRemoteId');
    });
  }

  QueryBuilder<ExternalTrackBinding, double?, QQueryOperations>
  trackerScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackerScore');
    });
  }

  QueryBuilder<ExternalTrackBinding, String?, QQueryOperations>
  trackerStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackerStatus');
    });
  }

  QueryBuilder<ExternalTrackBinding, TrackerType, QQueryOperations>
  trackerTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackerType');
    });
  }

  QueryBuilder<ExternalTrackBinding, int?, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
