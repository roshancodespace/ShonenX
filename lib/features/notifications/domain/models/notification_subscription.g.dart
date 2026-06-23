// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_subscription.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNotificationSubscriptionCollection on Isar {
  IsarCollection<NotificationSubscription> get notificationSubscriptions =>
      this.collection();
}

const NotificationSubscriptionSchema = CollectionSchema(
  name: r'NotificationSubscription',
  id: -2478578538553613853,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'image': PropertySchema(id: 1, name: r'image', type: IsarType.string),
    r'isEnabled': PropertySchema(
      id: 2,
      name: r'isEnabled',
      type: IsarType.bool,
    ),
    r'mode': PropertySchema(
      id: 3,
      name: r'mode',
      type: IsarType.string,
      enumMap: _NotificationSubscriptionmodeEnumValueMap,
    ),
    r'offsetMinutes': PropertySchema(
      id: 4,
      name: r'offsetMinutes',
      type: IsarType.long,
    ),
    r'referenceId': PropertySchema(
      id: 5,
      name: r'referenceId',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 6, name: r'title', type: IsarType.string),
    r'type': PropertySchema(
      id: 7,
      name: r'type',
      type: IsarType.string,
      enumMap: _NotificationSubscriptiontypeEnumValueMap,
    ),
    r'upcomingIdentifier': PropertySchema(
      id: 8,
      name: r'upcomingIdentifier',
      type: IsarType.string,
    ),
    r'upcomingTime': PropertySchema(
      id: 9,
      name: r'upcomingTime',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _notificationSubscriptionEstimateSize,
  serialize: _notificationSubscriptionSerialize,
  deserialize: _notificationSubscriptionDeserialize,
  deserializeProp: _notificationSubscriptionDeserializeProp,
  idName: r'id',
  indexes: {
    r'type_referenceId': IndexSchema(
      id: -6968502579601815679,
      name: r'type_referenceId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'referenceId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _notificationSubscriptionGetId,
  getLinks: _notificationSubscriptionGetLinks,
  attach: _notificationSubscriptionAttach,
  version: '3.3.0',
);

int _notificationSubscriptionEstimateSize(
  NotificationSubscription object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.image.length * 3;
  bytesCount += 3 + object.mode.name.length * 3;
  bytesCount += 3 + object.referenceId.length * 3;
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.name.length * 3;
  {
    final value = object.upcomingIdentifier;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _notificationSubscriptionSerialize(
  NotificationSubscription object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.image);
  writer.writeBool(offsets[2], object.isEnabled);
  writer.writeString(offsets[3], object.mode.name);
  writer.writeLong(offsets[4], object.offsetMinutes);
  writer.writeString(offsets[5], object.referenceId);
  writer.writeString(offsets[6], object.title);
  writer.writeString(offsets[7], object.type.name);
  writer.writeString(offsets[8], object.upcomingIdentifier);
  writer.writeDateTime(offsets[9], object.upcomingTime);
}

NotificationSubscription _notificationSubscriptionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NotificationSubscription();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.image = reader.readString(offsets[1]);
  object.isEnabled = reader.readBool(offsets[2]);
  object.mode =
      _NotificationSubscriptionmodeValueEnumMap[reader.readStringOrNull(
        offsets[3],
      )] ??
      SubscriptionMode.nextOnly;
  object.offsetMinutes = reader.readLong(offsets[4]);
  object.referenceId = reader.readString(offsets[5]);
  object.title = reader.readString(offsets[6]);
  object.type =
      _NotificationSubscriptiontypeValueEnumMap[reader.readStringOrNull(
        offsets[7],
      )] ??
      SubscriptionType.animeAiring;
  object.upcomingIdentifier = reader.readStringOrNull(offsets[8]);
  object.upcomingTime = reader.readDateTimeOrNull(offsets[9]);
  return object;
}

P _notificationSubscriptionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (_NotificationSubscriptionmodeValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              SubscriptionMode.nextOnly)
          as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (_NotificationSubscriptiontypeValueEnumMap[reader.readStringOrNull(
                offset,
              )] ??
              SubscriptionType.animeAiring)
          as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _NotificationSubscriptionmodeEnumValueMap = {
  r'nextOnly': r'nextOnly',
  r'entireSeason': r'entireSeason',
  r'targetEpisode': r'targetEpisode',
};
const _NotificationSubscriptionmodeValueEnumMap = {
  r'nextOnly': SubscriptionMode.nextOnly,
  r'entireSeason': SubscriptionMode.entireSeason,
  r'targetEpisode': SubscriptionMode.targetEpisode,
};
const _NotificationSubscriptiontypeEnumValueMap = {
  r'animeAiring': r'animeAiring',
  r'mangaChapter': r'mangaChapter',
  r'custom': r'custom',
};
const _NotificationSubscriptiontypeValueEnumMap = {
  r'animeAiring': SubscriptionType.animeAiring,
  r'mangaChapter': SubscriptionType.mangaChapter,
  r'custom': SubscriptionType.custom,
};

Id _notificationSubscriptionGetId(NotificationSubscription object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _notificationSubscriptionGetLinks(
  NotificationSubscription object,
) {
  return [];
}

void _notificationSubscriptionAttach(
  IsarCollection<dynamic> col,
  Id id,
  NotificationSubscription object,
) {
  object.id = id;
}

extension NotificationSubscriptionByIndex
    on IsarCollection<NotificationSubscription> {
  Future<NotificationSubscription?> getByTypeReferenceId(
    SubscriptionType type,
    String referenceId,
  ) {
    return getByIndex(r'type_referenceId', [type, referenceId]);
  }

  NotificationSubscription? getByTypeReferenceIdSync(
    SubscriptionType type,
    String referenceId,
  ) {
    return getByIndexSync(r'type_referenceId', [type, referenceId]);
  }

  Future<bool> deleteByTypeReferenceId(
    SubscriptionType type,
    String referenceId,
  ) {
    return deleteByIndex(r'type_referenceId', [type, referenceId]);
  }

  bool deleteByTypeReferenceIdSync(SubscriptionType type, String referenceId) {
    return deleteByIndexSync(r'type_referenceId', [type, referenceId]);
  }

  Future<List<NotificationSubscription?>> getAllByTypeReferenceId(
    List<SubscriptionType> typeValues,
    List<String> referenceIdValues,
  ) {
    final len = typeValues.length;
    assert(
      referenceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], referenceIdValues[i]]);
    }

    return getAllByIndex(r'type_referenceId', values);
  }

  List<NotificationSubscription?> getAllByTypeReferenceIdSync(
    List<SubscriptionType> typeValues,
    List<String> referenceIdValues,
  ) {
    final len = typeValues.length;
    assert(
      referenceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], referenceIdValues[i]]);
    }

    return getAllByIndexSync(r'type_referenceId', values);
  }

  Future<int> deleteAllByTypeReferenceId(
    List<SubscriptionType> typeValues,
    List<String> referenceIdValues,
  ) {
    final len = typeValues.length;
    assert(
      referenceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], referenceIdValues[i]]);
    }

    return deleteAllByIndex(r'type_referenceId', values);
  }

  int deleteAllByTypeReferenceIdSync(
    List<SubscriptionType> typeValues,
    List<String> referenceIdValues,
  ) {
    final len = typeValues.length;
    assert(
      referenceIdValues.length == len,
      'All index values must have the same length',
    );
    final values = <List<dynamic>>[];
    for (var i = 0; i < len; i++) {
      values.add([typeValues[i], referenceIdValues[i]]);
    }

    return deleteAllByIndexSync(r'type_referenceId', values);
  }

  Future<Id> putByTypeReferenceId(NotificationSubscription object) {
    return putByIndex(r'type_referenceId', object);
  }

  Id putByTypeReferenceIdSync(
    NotificationSubscription object, {
    bool saveLinks = true,
  }) {
    return putByIndexSync(r'type_referenceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByTypeReferenceId(
    List<NotificationSubscription> objects,
  ) {
    return putAllByIndex(r'type_referenceId', objects);
  }

  List<Id> putAllByTypeReferenceIdSync(
    List<NotificationSubscription> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(
      r'type_referenceId',
      objects,
      saveLinks: saveLinks,
    );
  }
}

extension NotificationSubscriptionQueryWhereSort
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QWhere
        > {
  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension NotificationSubscriptionQueryWhere
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QWhereClause
        > {
  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterWhereClause
  >
  typeEqualToAnyReferenceId(SubscriptionType type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'type_referenceId', value: [type]),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterWhereClause
  >
  typeNotEqualToAnyReferenceId(SubscriptionType type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [],
                upper: [type],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [type],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [type],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [],
                upper: [type],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterWhereClause
  >
  typeReferenceIdEqualTo(SubscriptionType type, String referenceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'type_referenceId',
          value: [type, referenceId],
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterWhereClause
  >
  typeEqualToReferenceIdNotEqualTo(SubscriptionType type, String referenceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [type],
                upper: [type, referenceId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [type, referenceId],
                includeLower: false,
                upper: [type],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [type, referenceId],
                includeLower: false,
                upper: [type],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'type_referenceId',
                lower: [type],
                upper: [type, referenceId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension NotificationSubscriptionQueryFilter
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QFilterCondition
        > {
  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'image',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'image',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'image',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'image',
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'image',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'image',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'image',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'image',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'image', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  imageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'image', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  isEnabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isEnabled', value: value),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeEqualTo(SubscriptionMode value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeGreaterThan(
    SubscriptionMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeLessThan(
    SubscriptionMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeBetween(
    SubscriptionMode lower,
    SubscriptionMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mode',
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  modeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mode', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  offsetMinutesEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'offsetMinutes', value: value),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  offsetMinutesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'offsetMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  offsetMinutesLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'offsetMinutes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  offsetMinutesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'offsetMinutes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'referenceId',
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'referenceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'referenceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'referenceId', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  referenceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'referenceId', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeEqualTo(SubscriptionType value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeGreaterThan(
    SubscriptionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeLessThan(
    SubscriptionType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeBetween(
    SubscriptionType lower,
    SubscriptionType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'upcomingIdentifier'),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'upcomingIdentifier'),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'upcomingIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'upcomingIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'upcomingIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'upcomingIdentifier',
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
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'upcomingIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'upcomingIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'upcomingIdentifier',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'upcomingIdentifier',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'upcomingIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingIdentifierIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'upcomingIdentifier', value: ''),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'upcomingTime'),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'upcomingTime'),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingTimeEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'upcomingTime', value: value),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingTimeGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'upcomingTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingTimeLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'upcomingTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    NotificationSubscription,
    NotificationSubscription,
    QAfterFilterCondition
  >
  upcomingTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'upcomingTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension NotificationSubscriptionQueryObject
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QFilterCondition
        > {}

extension NotificationSubscriptionQueryLinks
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QFilterCondition
        > {}

extension NotificationSubscriptionQuerySortBy
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QSortBy
        > {
  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByOffsetMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offsetMinutes', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByOffsetMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offsetMinutes', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByUpcomingIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingIdentifier', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByUpcomingIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingIdentifier', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByUpcomingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingTime', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  sortByUpcomingTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingTime', Sort.desc);
    });
  }
}

extension NotificationSubscriptionQuerySortThenBy
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QSortThenBy
        > {
  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByIsEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isEnabled', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByOffsetMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offsetMinutes', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByOffsetMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'offsetMinutes', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByReferenceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByReferenceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'referenceId', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByUpcomingIdentifier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingIdentifier', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByUpcomingIdentifierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingIdentifier', Sort.desc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByUpcomingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingTime', Sort.asc);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QAfterSortBy>
  thenByUpcomingTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'upcomingTime', Sort.desc);
    });
  }
}

extension NotificationSubscriptionQueryWhereDistinct
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QDistinct
        > {
  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByImage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'image', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByIsEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isEnabled');
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByMode({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByOffsetMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'offsetMinutes');
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByReferenceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'referenceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByUpcomingIdentifier({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'upcomingIdentifier',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<NotificationSubscription, NotificationSubscription, QDistinct>
  distinctByUpcomingTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'upcomingTime');
    });
  }
}

extension NotificationSubscriptionQueryProperty
    on
        QueryBuilder<
          NotificationSubscription,
          NotificationSubscription,
          QQueryProperty
        > {
  QueryBuilder<NotificationSubscription, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<NotificationSubscription, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<NotificationSubscription, String, QQueryOperations>
  imageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'image');
    });
  }

  QueryBuilder<NotificationSubscription, bool, QQueryOperations>
  isEnabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isEnabled');
    });
  }

  QueryBuilder<NotificationSubscription, SubscriptionMode, QQueryOperations>
  modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<NotificationSubscription, int, QQueryOperations>
  offsetMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'offsetMinutes');
    });
  }

  QueryBuilder<NotificationSubscription, String, QQueryOperations>
  referenceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'referenceId');
    });
  }

  QueryBuilder<NotificationSubscription, String, QQueryOperations>
  titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<NotificationSubscription, SubscriptionType, QQueryOperations>
  typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<NotificationSubscription, String?, QQueryOperations>
  upcomingIdentifierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'upcomingIdentifier');
    });
  }

  QueryBuilder<NotificationSubscription, DateTime?, QQueryOperations>
  upcomingTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'upcomingTime');
    });
  }
}
