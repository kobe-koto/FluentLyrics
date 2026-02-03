// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyric_cache.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLyricCacheCollection on Isar {
  IsarCollection<LyricCache> get lyricCaches => this.collection();
}

const LyricCacheSchema = CollectionSchema(
  name: r'LyricCache',
  id: -8078122028402574331,
  properties: {
    r'artworkUrl': PropertySchema(
      id: 0,
      name: r'artworkUrl',
      type: IsarType.string,
    ),
    r'cacheId': PropertySchema(
      id: 1,
      name: r'cacheId',
      type: IsarType.string,
    ),
    r'composer': PropertySchema(
      id: 2,
      name: r'composer',
      type: IsarType.string,
    ),
    r'contributor': PropertySchema(
      id: 3,
      name: r'contributor',
      type: IsarType.string,
    ),
    r'copyright': PropertySchema(
      id: 4,
      name: r'copyright',
      type: IsarType.string,
    ),
    r'isPureMusic': PropertySchema(
      id: 5,
      name: r'isPureMusic',
      type: IsarType.bool,
    ),
    r'isRichSync': PropertySchema(
      id: 6,
      name: r'isRichSync',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 7,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lyrics': PropertySchema(
      id: 8,
      name: r'lyrics',
      type: IsarType.objectList,
      target: r'LyricItem',
    ),
    r'source': PropertySchema(
      id: 9,
      name: r'source',
      type: IsarType.string,
    ),
    r'writtenBy': PropertySchema(
      id: 10,
      name: r'writtenBy',
      type: IsarType.string,
    )
  },
  estimateSize: _lyricCacheEstimateSize,
  serialize: _lyricCacheSerialize,
  deserialize: _lyricCacheDeserialize,
  deserializeProp: _lyricCacheDeserializeProp,
  idName: r'id',
  indexes: {
    r'cacheId': IndexSchema(
      id: -7372113173438779531,
      name: r'cacheId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'cacheId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'LyricItem': LyricItemSchema,
    r'LyricItemInlinePart': LyricItemInlinePartSchema
  },
  getId: _lyricCacheGetId,
  getLinks: _lyricCacheGetLinks,
  attach: _lyricCacheAttach,
  version: '3.1.0+1',
);

int _lyricCacheEstimateSize(
  LyricCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.artworkUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.cacheId.length * 3;
  {
    final value = object.composer;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.contributor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.copyright;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.lyrics.length * 3;
  {
    final offsets = allOffsets[LyricItem]!;
    for (var i = 0; i < object.lyrics.length; i++) {
      final value = object.lyrics[i];
      bytesCount += LyricItemSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.source.length * 3;
  {
    final value = object.writtenBy;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _lyricCacheSerialize(
  LyricCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.artworkUrl);
  writer.writeString(offsets[1], object.cacheId);
  writer.writeString(offsets[2], object.composer);
  writer.writeString(offsets[3], object.contributor);
  writer.writeString(offsets[4], object.copyright);
  writer.writeBool(offsets[5], object.isPureMusic);
  writer.writeBool(offsets[6], object.isRichSync);
  writer.writeBool(offsets[7], object.isSynced);
  writer.writeObjectList<LyricItem>(
    offsets[8],
    allOffsets,
    LyricItemSchema.serialize,
    object.lyrics,
  );
  writer.writeString(offsets[9], object.source);
  writer.writeString(offsets[10], object.writtenBy);
}

LyricCache _lyricCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LyricCache();
  object.artworkUrl = reader.readStringOrNull(offsets[0]);
  object.cacheId = reader.readString(offsets[1]);
  object.composer = reader.readStringOrNull(offsets[2]);
  object.contributor = reader.readStringOrNull(offsets[3]);
  object.copyright = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.isPureMusic = reader.readBool(offsets[5]);
  object.isRichSync = reader.readBool(offsets[6]);
  object.isSynced = reader.readBool(offsets[7]);
  object.lyrics = reader.readObjectList<LyricItem>(
        offsets[8],
        LyricItemSchema.deserialize,
        allOffsets,
        LyricItem(),
      ) ??
      [];
  object.source = reader.readString(offsets[9]);
  object.writtenBy = reader.readStringOrNull(offsets[10]);
  return object;
}

P _lyricCacheDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readObjectList<LyricItem>(
            offset,
            LyricItemSchema.deserialize,
            allOffsets,
            LyricItem(),
          ) ??
          []) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _lyricCacheGetId(LyricCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _lyricCacheGetLinks(LyricCache object) {
  return [];
}

void _lyricCacheAttach(IsarCollection<dynamic> col, Id id, LyricCache object) {
  object.id = id;
}

extension LyricCacheByIndex on IsarCollection<LyricCache> {
  Future<LyricCache?> getByCacheId(String cacheId) {
    return getByIndex(r'cacheId', [cacheId]);
  }

  LyricCache? getByCacheIdSync(String cacheId) {
    return getByIndexSync(r'cacheId', [cacheId]);
  }

  Future<bool> deleteByCacheId(String cacheId) {
    return deleteByIndex(r'cacheId', [cacheId]);
  }

  bool deleteByCacheIdSync(String cacheId) {
    return deleteByIndexSync(r'cacheId', [cacheId]);
  }

  Future<List<LyricCache?>> getAllByCacheId(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'cacheId', values);
  }

  List<LyricCache?> getAllByCacheIdSync(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'cacheId', values);
  }

  Future<int> deleteAllByCacheId(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'cacheId', values);
  }

  int deleteAllByCacheIdSync(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'cacheId', values);
  }

  Future<Id> putByCacheId(LyricCache object) {
    return putByIndex(r'cacheId', object);
  }

  Id putByCacheIdSync(LyricCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'cacheId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCacheId(List<LyricCache> objects) {
    return putAllByIndex(r'cacheId', objects);
  }

  List<Id> putAllByCacheIdSync(List<LyricCache> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'cacheId', objects, saveLinks: saveLinks);
  }
}

extension LyricCacheQueryWhereSort
    on QueryBuilder<LyricCache, LyricCache, QWhere> {
  QueryBuilder<LyricCache, LyricCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LyricCacheQueryWhere
    on QueryBuilder<LyricCache, LyricCache, QWhereClause> {
  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> cacheIdEqualTo(
      String cacheId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cacheId',
        value: [cacheId],
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> cacheIdNotEqualTo(
      String cacheId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [],
              upper: [cacheId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [cacheId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [cacheId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cacheId',
              lower: [],
              upper: [cacheId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LyricCacheQueryFilter
    on QueryBuilder<LyricCache, LyricCache, QFilterCondition> {
  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'artworkUrl',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'artworkUrl',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> artworkUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> artworkUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'artworkUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'artworkUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> artworkUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'artworkUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'artworkUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      artworkUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'artworkUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      cacheIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cacheId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cacheId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cacheId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheId',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      cacheIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cacheId',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'composer',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      composerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'composer',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'composer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      composerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'composer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'composer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'composer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      composerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'composer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'composer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'composer',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'composer',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      composerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'composer',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      composerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'composer',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contributor',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contributor',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contributor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contributor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contributor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contributor',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      contributorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contributor',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      copyrightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'copyright',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      copyrightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'copyright',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'copyright',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      copyrightGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'copyright',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'copyright',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'copyright',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      copyrightStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'copyright',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'copyright',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'copyright',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'copyright',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      copyrightIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'copyright',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      copyrightIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'copyright',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      isPureMusicEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPureMusic',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> isRichSyncEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRichSync',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      lyricsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> lyricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      lyricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      lyricsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      lyricsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      lyricsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'lyrics',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      writtenByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'writtenBy',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      writtenByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'writtenBy',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'writtenBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      writtenByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'writtenBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'writtenBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'writtenBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      writtenByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'writtenBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'writtenBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'writtenBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'writtenBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      writtenByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'writtenBy',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
      writtenByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'writtenBy',
        value: '',
      ));
    });
  }
}

extension LyricCacheQueryObject
    on QueryBuilder<LyricCache, LyricCache, QFilterCondition> {
  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> lyricsElement(
      FilterQuery<LyricItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'lyrics');
    });
  }
}

extension LyricCacheQueryLinks
    on QueryBuilder<LyricCache, LyricCache, QFilterCondition> {}

extension LyricCacheQuerySortBy
    on QueryBuilder<LyricCache, LyricCache, QSortBy> {
  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByArtworkUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByArtworkUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByCacheId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByCacheIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByComposer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'composer', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByComposerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'composer', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByContributor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributor', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByContributorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributor', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByCopyright() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'copyright', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByCopyrightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'copyright', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByIsPureMusic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPureMusic', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByIsPureMusicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPureMusic', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByIsRichSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRichSync', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByIsRichSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRichSync', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByWrittenBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'writtenBy', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortByWrittenByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'writtenBy', Sort.desc);
    });
  }
}

extension LyricCacheQuerySortThenBy
    on QueryBuilder<LyricCache, LyricCache, QSortThenBy> {
  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByArtworkUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByArtworkUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'artworkUrl', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByCacheId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByCacheIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByComposer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'composer', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByComposerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'composer', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByContributor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributor', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByContributorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contributor', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByCopyright() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'copyright', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByCopyrightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'copyright', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByIsPureMusic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPureMusic', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByIsPureMusicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPureMusic', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByIsRichSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRichSync', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByIsRichSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRichSync', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByWrittenBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'writtenBy', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenByWrittenByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'writtenBy', Sort.desc);
    });
  }
}

extension LyricCacheQueryWhereDistinct
    on QueryBuilder<LyricCache, LyricCache, QDistinct> {
  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByArtworkUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'artworkUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByCacheId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByComposer(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'composer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByContributor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contributor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByCopyright(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'copyright', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByIsPureMusic() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPureMusic');
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByIsRichSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRichSync');
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByWrittenBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'writtenBy', caseSensitive: caseSensitive);
    });
  }
}

extension LyricCacheQueryProperty
    on QueryBuilder<LyricCache, LyricCache, QQueryProperty> {
  QueryBuilder<LyricCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LyricCache, String?, QQueryOperations> artworkUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'artworkUrl');
    });
  }

  QueryBuilder<LyricCache, String, QQueryOperations> cacheIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheId');
    });
  }

  QueryBuilder<LyricCache, String?, QQueryOperations> composerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'composer');
    });
  }

  QueryBuilder<LyricCache, String?, QQueryOperations> contributorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contributor');
    });
  }

  QueryBuilder<LyricCache, String?, QQueryOperations> copyrightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'copyright');
    });
  }

  QueryBuilder<LyricCache, bool, QQueryOperations> isPureMusicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPureMusic');
    });
  }

  QueryBuilder<LyricCache, bool, QQueryOperations> isRichSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRichSync');
    });
  }

  QueryBuilder<LyricCache, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<LyricCache, List<LyricItem>, QQueryOperations> lyricsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lyrics');
    });
  }

  QueryBuilder<LyricCache, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<LyricCache, String?, QQueryOperations> writtenByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'writtenBy');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const LyricItemSchema = Schema(
  name: r'LyricItem',
  id: -6466334837918240129,
  properties: {
    r'endTimeMs': PropertySchema(
      id: 0,
      name: r'endTimeMs',
      type: IsarType.long,
    ),
    r'inlineParts': PropertySchema(
      id: 1,
      name: r'inlineParts',
      type: IsarType.objectList,
      target: r'LyricItemInlinePart',
    ),
    r'startTimeMs': PropertySchema(
      id: 2,
      name: r'startTimeMs',
      type: IsarType.long,
    ),
    r'text': PropertySchema(
      id: 3,
      name: r'text',
      type: IsarType.string,
    )
  },
  estimateSize: _lyricItemEstimateSize,
  serialize: _lyricItemSerialize,
  deserialize: _lyricItemDeserialize,
  deserializeProp: _lyricItemDeserializeProp,
);

int _lyricItemEstimateSize(
  LyricItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.inlineParts;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[LyricItemInlinePart]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += LyricItemInlinePartSchema.estimateSize(
              value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _lyricItemSerialize(
  LyricItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endTimeMs);
  writer.writeObjectList<LyricItemInlinePart>(
    offsets[1],
    allOffsets,
    LyricItemInlinePartSchema.serialize,
    object.inlineParts,
  );
  writer.writeLong(offsets[2], object.startTimeMs);
  writer.writeString(offsets[3], object.text);
}

LyricItem _lyricItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LyricItem();
  object.endTimeMs = reader.readLongOrNull(offsets[0]);
  object.inlineParts = reader.readObjectList<LyricItemInlinePart>(
    offsets[1],
    LyricItemInlinePartSchema.deserialize,
    allOffsets,
    LyricItemInlinePart(),
  );
  object.startTimeMs = reader.readLong(offsets[2]);
  object.text = reader.readString(offsets[3]);
  return object;
}

P _lyricItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readObjectList<LyricItemInlinePart>(
        offset,
        LyricItemInlinePartSchema.deserialize,
        allOffsets,
        LyricItemInlinePart(),
      )) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension LyricItemQueryFilter
    on QueryBuilder<LyricItem, LyricItem, QFilterCondition> {
  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> endTimeMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endTimeMs',
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      endTimeMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endTimeMs',
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> endTimeMsEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      endTimeMsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> endTimeMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> endTimeMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTimeMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'inlineParts',
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'inlineParts',
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inlineParts',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inlineParts',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inlineParts',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inlineParts',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inlineParts',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      inlinePartsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'inlineParts',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> startTimeMsEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
      startTimeMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> startTimeMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> startTimeMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTimeMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }
}

extension LyricItemQueryObject
    on QueryBuilder<LyricItem, LyricItem, QFilterCondition> {
  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> inlinePartsElement(
      FilterQuery<LyricItemInlinePart> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'inlineParts');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const LyricItemInlinePartSchema = Schema(
  name: r'LyricItemInlinePart',
  id: -7656588683398414576,
  properties: {
    r'endTimeMs': PropertySchema(
      id: 0,
      name: r'endTimeMs',
      type: IsarType.long,
    ),
    r'startTimeMs': PropertySchema(
      id: 1,
      name: r'startTimeMs',
      type: IsarType.long,
    ),
    r'text': PropertySchema(
      id: 2,
      name: r'text',
      type: IsarType.string,
    )
  },
  estimateSize: _lyricItemInlinePartEstimateSize,
  serialize: _lyricItemInlinePartSerialize,
  deserialize: _lyricItemInlinePartDeserialize,
  deserializeProp: _lyricItemInlinePartDeserializeProp,
);

int _lyricItemInlinePartEstimateSize(
  LyricItemInlinePart object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _lyricItemInlinePartSerialize(
  LyricItemInlinePart object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endTimeMs);
  writer.writeLong(offsets[1], object.startTimeMs);
  writer.writeString(offsets[2], object.text);
}

LyricItemInlinePart _lyricItemInlinePartDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LyricItemInlinePart();
  object.endTimeMs = reader.readLong(offsets[0]);
  object.startTimeMs = reader.readLong(offsets[1]);
  object.text = reader.readString(offsets[2]);
  return object;
}

P _lyricItemInlinePartDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension LyricItemInlinePartQueryFilter on QueryBuilder<LyricItemInlinePart,
    LyricItemInlinePart, QFilterCondition> {
  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      endTimeMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      endTimeMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      endTimeMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      endTimeMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endTimeMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      startTimeMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      startTimeMsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      startTimeMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startTimeMs',
        value: value,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      startTimeMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startTimeMs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'text',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'text',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'text',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'text',
        value: '',
      ));
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
      textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'text',
        value: '',
      ));
    });
  }
}

extension LyricItemInlinePartQueryObject on QueryBuilder<LyricItemInlinePart,
    LyricItemInlinePart, QFilterCondition> {}
