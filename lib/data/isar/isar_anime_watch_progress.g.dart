// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_anime_watch_progress.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarAnimeWatchProgressCollection on Isar {
  IsarCollection<IsarAnimeWatchProgress> get isarAnimeWatchProgress =>
      this.collection();
}

const IsarAnimeWatchProgressSchema = CollectionSchema(
  name: r'IsarAnimeWatchProgress',
  id: 5920720567613655388,
  properties: {
    r'animeCover': PropertySchema(
      id: 0,
      name: r'animeCover',
      type: IsarType.string,
    ),
    r'animeFormat': PropertySchema(
      id: 1,
      name: r'animeFormat',
      type: IsarType.string,
    ),
    r'animeId': PropertySchema(id: 2, name: r'animeId', type: IsarType.string),
    r'animeTitle': PropertySchema(
      id: 3,
      name: r'animeTitle',
      type: IsarType.string,
    ),
    r'currentEpisode': PropertySchema(
      id: 4,
      name: r'currentEpisode',
      type: IsarType.long,
    ),
    r'episodesProgress': PropertySchema(
      id: 5,
      name: r'episodesProgress',
      type: IsarType.objectList,

      target: r'IsarEpisodeProgress',
    ),
    r'lastUpdated': PropertySchema(
      id: 6,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'sourceSelection': PropertySchema(
      id: 7,
      name: r'sourceSelection',
      type: IsarType.object,

      target: r'IsarSourceSelection',
    ),
    r'status': PropertySchema(id: 8, name: r'status', type: IsarType.string),
    r'totalEpisodes': PropertySchema(
      id: 9,
      name: r'totalEpisodes',
      type: IsarType.long,
    ),
  },

  estimateSize: _isarAnimeWatchProgressEstimateSize,
  serialize: _isarAnimeWatchProgressSerialize,
  deserialize: _isarAnimeWatchProgressDeserialize,
  deserializeProp: _isarAnimeWatchProgressDeserializeProp,
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
  embeddedSchemas: {
    r'IsarEpisodeProgress': IsarEpisodeProgressSchema,
    r'IsarSourceSelection': IsarSourceSelectionSchema,
  },

  getId: _isarAnimeWatchProgressGetId,
  getLinks: _isarAnimeWatchProgressGetLinks,
  attach: _isarAnimeWatchProgressAttach,
  version: '3.3.0',
);

int _isarAnimeWatchProgressEstimateSize(
  IsarAnimeWatchProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.animeCover.length * 3;
  {
    final value = object.animeFormat;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.animeId.length * 3;
  bytesCount += 3 + object.animeTitle.length * 3;
  bytesCount += 3 + object.episodesProgress.length * 3;
  {
    final offsets = allOffsets[IsarEpisodeProgress]!;
    for (var i = 0; i < object.episodesProgress.length; i++) {
      final value = object.episodesProgress[i];
      bytesCount += IsarEpisodeProgressSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  {
    final value = object.sourceSelection;
    if (value != null) {
      bytesCount +=
          3 +
          IsarSourceSelectionSchema.estimateSize(
            value,
            allOffsets[IsarSourceSelection]!,
            allOffsets,
          );
    }
  }
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _isarAnimeWatchProgressSerialize(
  IsarAnimeWatchProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.animeCover);
  writer.writeString(offsets[1], object.animeFormat);
  writer.writeString(offsets[2], object.animeId);
  writer.writeString(offsets[3], object.animeTitle);
  writer.writeLong(offsets[4], object.currentEpisode);
  writer.writeObjectList<IsarEpisodeProgress>(
    offsets[5],
    allOffsets,
    IsarEpisodeProgressSchema.serialize,
    object.episodesProgress,
  );
  writer.writeDateTime(offsets[6], object.lastUpdated);
  writer.writeObject<IsarSourceSelection>(
    offsets[7],
    allOffsets,
    IsarSourceSelectionSchema.serialize,
    object.sourceSelection,
  );
  writer.writeString(offsets[8], object.status);
  writer.writeLong(offsets[9], object.totalEpisodes);
}

IsarAnimeWatchProgress _isarAnimeWatchProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarAnimeWatchProgress(
    animeCover: reader.readString(offsets[0]),
    animeFormat: reader.readStringOrNull(offsets[1]),
    animeId: reader.readString(offsets[2]),
    animeTitle: reader.readString(offsets[3]),
    currentEpisode: reader.readLongOrNull(offsets[4]) ?? 1,
    episodesProgress:
        reader.readObjectList<IsarEpisodeProgress>(
          offsets[5],
          IsarEpisodeProgressSchema.deserialize,
          allOffsets,
          IsarEpisodeProgress(),
        ) ??
        const [],
    id: id,
    lastUpdated: reader.readDateTimeOrNull(offsets[6]),
    sourceSelection: reader.readObjectOrNull<IsarSourceSelection>(
      offsets[7],
      IsarSourceSelectionSchema.deserialize,
      allOffsets,
    ),
    status: reader.readStringOrNull(offsets[8]) ?? 'watching',
    totalEpisodes: reader.readLong(offsets[9]),
  );
  return object;
}

P _isarAnimeWatchProgressDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 5:
      return (reader.readObjectList<IsarEpisodeProgress>(
                offset,
                IsarEpisodeProgressSchema.deserialize,
                allOffsets,
                IsarEpisodeProgress(),
              ) ??
              const [])
          as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readObjectOrNull<IsarSourceSelection>(
            offset,
            IsarSourceSelectionSchema.deserialize,
            allOffsets,
          ))
          as P;
    case 8:
      return (reader.readStringOrNull(offset) ?? 'watching') as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarAnimeWatchProgressGetId(IsarAnimeWatchProgress object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _isarAnimeWatchProgressGetLinks(
  IsarAnimeWatchProgress object,
) {
  return [];
}

void _isarAnimeWatchProgressAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarAnimeWatchProgress object,
) {
  object.id = id;
}

extension IsarAnimeWatchProgressByIndex
    on IsarCollection<IsarAnimeWatchProgress> {
  Future<IsarAnimeWatchProgress?> getByAnimeId(String animeId) {
    return getByIndex(r'animeId', [animeId]);
  }

  IsarAnimeWatchProgress? getByAnimeIdSync(String animeId) {
    return getByIndexSync(r'animeId', [animeId]);
  }

  Future<bool> deleteByAnimeId(String animeId) {
    return deleteByIndex(r'animeId', [animeId]);
  }

  bool deleteByAnimeIdSync(String animeId) {
    return deleteByIndexSync(r'animeId', [animeId]);
  }

  Future<List<IsarAnimeWatchProgress?>> getAllByAnimeId(
    List<String> animeIdValues,
  ) {
    final values = animeIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'animeId', values);
  }

  List<IsarAnimeWatchProgress?> getAllByAnimeIdSync(
    List<String> animeIdValues,
  ) {
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

  Future<Id> putByAnimeId(IsarAnimeWatchProgress object) {
    return putByIndex(r'animeId', object);
  }

  Id putByAnimeIdSync(IsarAnimeWatchProgress object, {bool saveLinks = true}) {
    return putByIndexSync(r'animeId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAnimeId(List<IsarAnimeWatchProgress> objects) {
    return putAllByIndex(r'animeId', objects);
  }

  List<Id> putAllByAnimeIdSync(
    List<IsarAnimeWatchProgress> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'animeId', objects, saveLinks: saveLinks);
  }
}

extension IsarAnimeWatchProgressQueryWhereSort
    on QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QWhere> {
  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarAnimeWatchProgressQueryWhere
    on
        QueryBuilder<
          IsarAnimeWatchProgress,
          IsarAnimeWatchProgress,
          QWhereClause
        > {
  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterWhereClause
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterWhereClause
  >
  animeIdEqualTo(String animeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'animeId', value: [animeId]),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterWhereClause
  >
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

extension IsarAnimeWatchProgressQueryFilter
    on
        QueryBuilder<
          IsarAnimeWatchProgress,
          IsarAnimeWatchProgress,
          QFilterCondition
        > {
  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeCoverEqualTo(String value, {bool caseSensitive = true}) {
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeCoverGreaterThan(
    String value, {
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeCoverLessThan(
    String value, {
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeCoverBetween(
    String lower,
    String upper, {
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'animeFormat'),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'animeFormat'),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'animeFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'animeFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'animeFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'animeFormat',
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'animeFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'animeFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'animeFormat',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'animeFormat',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'animeFormat', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeFormatIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'animeFormat', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'animeTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  animeTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'animeTitle', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  currentEpisodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'currentEpisode', value: value),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  currentEpisodeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'currentEpisode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  currentEpisodeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'currentEpisode',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  currentEpisodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'currentEpisode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  episodesProgressLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'episodesProgress', length, true, length, true);
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  episodesProgressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'episodesProgress', 0, true, 0, true);
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  episodesProgressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'episodesProgress', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  episodesProgressLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'episodesProgress', 0, true, length, include);
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  episodesProgressLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodesProgress',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  episodesProgressLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'episodesProgress',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  lastUpdatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastUpdated'),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  lastUpdatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastUpdated'),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  lastUpdatedEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUpdated', value: value),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  lastUpdatedGreaterThan(DateTime? value, {bool include = false}) {
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  lastUpdatedLessThan(DateTime? value, {bool include = false}) {
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  lastUpdatedBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  sourceSelectionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceSelection'),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  sourceSelectionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceSelection'),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
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
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  totalEpisodesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'totalEpisodes', value: value),
      );
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  totalEpisodesGreaterThan(int value, {bool include = false}) {
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  totalEpisodesLessThan(int value, {bool include = false}) {
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

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  totalEpisodesBetween(
    int lower,
    int upper, {
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

extension IsarAnimeWatchProgressQueryObject
    on
        QueryBuilder<
          IsarAnimeWatchProgress,
          IsarAnimeWatchProgress,
          QFilterCondition
        > {
  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  episodesProgressElement(FilterQuery<IsarEpisodeProgress> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'episodesProgress');
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    IsarAnimeWatchProgress,
    QAfterFilterCondition
  >
  sourceSelection(FilterQuery<IsarSourceSelection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'sourceSelection');
    });
  }
}

extension IsarAnimeWatchProgressQueryLinks
    on
        QueryBuilder<
          IsarAnimeWatchProgress,
          IsarAnimeWatchProgress,
          QFilterCondition
        > {}

extension IsarAnimeWatchProgressQuerySortBy
    on QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QSortBy> {
  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeFormat', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeFormat', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByAnimeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByCurrentEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentEpisode', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByCurrentEpisodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentEpisode', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  sortByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }
}

extension IsarAnimeWatchProgressQuerySortThenBy
    on
        QueryBuilder<
          IsarAnimeWatchProgress,
          IsarAnimeWatchProgress,
          QSortThenBy
        > {
  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeCover() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeCoverDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeCover', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeFormat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeFormat', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeFormatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeFormat', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeId', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByAnimeTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'animeTitle', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByCurrentEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentEpisode', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByCurrentEpisodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentEpisode', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.asc);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QAfterSortBy>
  thenByTotalEpisodesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalEpisodes', Sort.desc);
    });
  }
}

extension IsarAnimeWatchProgressQueryWhereDistinct
    on QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct> {
  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByAnimeCover({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeCover', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByAnimeFormat({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeFormat', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByAnimeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByAnimeTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'animeTitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByCurrentEpisode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentEpisode');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarAnimeWatchProgress, QDistinct>
  distinctByTotalEpisodes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalEpisodes');
    });
  }
}

extension IsarAnimeWatchProgressQueryProperty
    on
        QueryBuilder<
          IsarAnimeWatchProgress,
          IsarAnimeWatchProgress,
          QQueryProperty
        > {
  QueryBuilder<IsarAnimeWatchProgress, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, String, QQueryOperations>
  animeCoverProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeCover');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, String?, QQueryOperations>
  animeFormatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeFormat');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, String, QQueryOperations>
  animeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeId');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, String, QQueryOperations>
  animeTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'animeTitle');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, int, QQueryOperations>
  currentEpisodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentEpisode');
    });
  }

  QueryBuilder<
    IsarAnimeWatchProgress,
    List<IsarEpisodeProgress>,
    QQueryOperations
  >
  episodesProgressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'episodesProgress');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, DateTime?, QQueryOperations>
  lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, IsarSourceSelection?, QQueryOperations>
  sourceSelectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceSelection');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<IsarAnimeWatchProgress, int, QQueryOperations>
  totalEpisodesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalEpisodes');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const IsarEpisodeProgressSchema = Schema(
  name: r'IsarEpisodeProgress',
  id: -1946433157924574348,
  properties: {
    r'durationInSeconds': PropertySchema(
      id: 0,
      name: r'durationInSeconds',
      type: IsarType.long,
    ),
    r'episodeNumber': PropertySchema(
      id: 1,
      name: r'episodeNumber',
      type: IsarType.long,
    ),
    r'episodeThumbnail': PropertySchema(
      id: 2,
      name: r'episodeThumbnail',
      type: IsarType.string,
    ),
    r'episodeTitle': PropertySchema(
      id: 3,
      name: r'episodeTitle',
      type: IsarType.string,
    ),
    r'isCompleted': PropertySchema(
      id: 4,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'progressInSeconds': PropertySchema(
      id: 5,
      name: r'progressInSeconds',
      type: IsarType.long,
    ),
    r'watchedAt': PropertySchema(
      id: 6,
      name: r'watchedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _isarEpisodeProgressEstimateSize,
  serialize: _isarEpisodeProgressSerialize,
  deserialize: _isarEpisodeProgressDeserialize,
  deserializeProp: _isarEpisodeProgressDeserializeProp,
);

int _isarEpisodeProgressEstimateSize(
  IsarEpisodeProgress object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.episodeThumbnail;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.episodeTitle.length * 3;
  return bytesCount;
}

void _isarEpisodeProgressSerialize(
  IsarEpisodeProgress object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.durationInSeconds);
  writer.writeLong(offsets[1], object.episodeNumber);
  writer.writeString(offsets[2], object.episodeThumbnail);
  writer.writeString(offsets[3], object.episodeTitle);
  writer.writeBool(offsets[4], object.isCompleted);
  writer.writeLong(offsets[5], object.progressInSeconds);
  writer.writeDateTime(offsets[6], object.watchedAt);
}

IsarEpisodeProgress _isarEpisodeProgressDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarEpisodeProgress(
    durationInSeconds: reader.readLongOrNull(offsets[0]),
    episodeNumber: reader.readLongOrNull(offsets[1]) ?? 0,
    episodeThumbnail: reader.readStringOrNull(offsets[2]),
    episodeTitle: reader.readStringOrNull(offsets[3]) ?? '',
    isCompleted: reader.readBoolOrNull(offsets[4]) ?? false,
    progressInSeconds: reader.readLongOrNull(offsets[5]),
    watchedAt: reader.readDateTimeOrNull(offsets[6]),
  );
  return object;
}

P _isarEpisodeProgressDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 4:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension IsarEpisodeProgressQueryFilter
    on
        QueryBuilder<
          IsarEpisodeProgress,
          IsarEpisodeProgress,
          QFilterCondition
        > {
  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  durationInSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'durationInSeconds'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  durationInSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'durationInSeconds'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  durationInSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'durationInSeconds', value: value),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  durationInSecondsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'durationInSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  durationInSecondsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'durationInSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  durationInSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'durationInSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeNumberEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'episodeNumber', value: value),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeNumberGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'episodeNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeNumberLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'episodeNumber',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeNumberBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'episodeNumber',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'episodeThumbnail'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'episodeThumbnail'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'episodeThumbnail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'episodeThumbnail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'episodeThumbnail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'episodeThumbnail',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'episodeThumbnail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'episodeThumbnail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'episodeThumbnail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'episodeThumbnail',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'episodeThumbnail', value: ''),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeThumbnailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'episodeThumbnail', value: ''),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeTitleEqualTo(String value, {bool caseSensitive = true}) {
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeTitleGreaterThan(
    String value, {
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeTitleLessThan(
    String value, {
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeTitleBetween(
    String lower,
    String upper, {
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
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

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'episodeTitle', value: ''),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  episodeTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'episodeTitle', value: ''),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isCompleted', value: value),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  progressInSecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'progressInSeconds'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  progressInSecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'progressInSeconds'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  progressInSecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'progressInSeconds', value: value),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  progressInSecondsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'progressInSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  progressInSecondsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'progressInSeconds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  progressInSecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'progressInSeconds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  watchedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'watchedAt'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  watchedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'watchedAt'),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  watchedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'watchedAt', value: value),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  watchedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'watchedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  watchedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'watchedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<IsarEpisodeProgress, IsarEpisodeProgress, QAfterFilterCondition>
  watchedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'watchedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarEpisodeProgressQueryObject
    on
        QueryBuilder<
          IsarEpisodeProgress,
          IsarEpisodeProgress,
          QFilterCondition
        > {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const IsarSourceSelectionSchema = Schema(
  name: r'IsarSourceSelection',
  id: 5973140715962261930,
  properties: {
    r'matchedAnimeId': PropertySchema(
      id: 0,
      name: r'matchedAnimeId',
      type: IsarType.string,
    ),
    r'matchedAnimeTitle': PropertySchema(
      id: 1,
      name: r'matchedAnimeTitle',
      type: IsarType.string,
    ),
    r'sourceId': PropertySchema(
      id: 2,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'sourceType': PropertySchema(
      id: 3,
      name: r'sourceType',
      type: IsarType.string,
    ),
  },

  estimateSize: _isarSourceSelectionEstimateSize,
  serialize: _isarSourceSelectionSerialize,
  deserialize: _isarSourceSelectionDeserialize,
  deserializeProp: _isarSourceSelectionDeserializeProp,
);

int _isarSourceSelectionEstimateSize(
  IsarSourceSelection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
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

void _isarSourceSelectionSerialize(
  IsarSourceSelection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.matchedAnimeId);
  writer.writeString(offsets[1], object.matchedAnimeTitle);
  writer.writeString(offsets[2], object.sourceId);
  writer.writeString(offsets[3], object.sourceType);
}

IsarSourceSelection _isarSourceSelectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarSourceSelection(
    matchedAnimeId: reader.readStringOrNull(offsets[0]),
    matchedAnimeTitle: reader.readStringOrNull(offsets[1]),
    sourceId: reader.readStringOrNull(offsets[2]),
    sourceType: reader.readStringOrNull(offsets[3]),
  );
  return object;
}

P _isarSourceSelectionDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension IsarSourceSelectionQueryFilter
    on
        QueryBuilder<
          IsarSourceSelection,
          IsarSourceSelection,
          QFilterCondition
        > {
  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'matchedAnimeId'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'matchedAnimeId'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchedAnimeId', value: ''),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchedAnimeId', value: ''),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'matchedAnimeTitle'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'matchedAnimeTitle'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'matchedAnimeTitle', value: ''),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  matchedAnimeTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'matchedAnimeTitle', value: ''),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceId'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceType'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceType'),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
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

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceType', value: ''),
      );
    });
  }

  QueryBuilder<IsarSourceSelection, IsarSourceSelection, QAfterFilterCondition>
  sourceTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceType', value: ''),
      );
    });
  }
}

extension IsarSourceSelectionQueryObject
    on
        QueryBuilder<
          IsarSourceSelection,
          IsarSourceSelection,
          QFilterCondition
        > {}
