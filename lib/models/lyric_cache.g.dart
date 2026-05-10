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
    r'artworkUrls': PropertySchema(
      id: 0,
      name: r'artworkUrls',
      type: IsarType.stringList,
    ),
    r'cacheId': PropertySchema(id: 1, name: r'cacheId', type: IsarType.string),
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
    r'isSynced': PropertySchema(id: 7, name: r'isSynced', type: IsarType.bool),
    r'lyrics': PropertySchema(
      id: 8,
      name: r'lyrics',
      type: IsarType.objectList,

      target: r'LyricItem',
    ),
    r'source': PropertySchema(id: 9, name: r'source', type: IsarType.string),
    r'sourceProvider': PropertySchema(
      id: 10,
      name: r'sourceProvider',
      type: IsarType.string,
    ),
    r'writtenBy': PropertySchema(
      id: 11,
      name: r'writtenBy',
      type: IsarType.string,
    ),
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'LyricItem': LyricItemSchema,
    r'LyricItemInlinePart': LyricItemInlinePartSchema,
  },

  getId: _lyricCacheGetId,
  getLinks: _lyricCacheGetLinks,
  attach: _lyricCacheAttach,
  version: '3.3.2',
);

int _lyricCacheEstimateSize(
  LyricCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.artworkUrls;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
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
    final value = object.sourceProvider;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
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
  writer.writeStringList(offsets[0], object.artworkUrls);
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
  writer.writeString(offsets[10], object.sourceProvider);
  writer.writeString(offsets[11], object.writtenBy);
}

LyricCache _lyricCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LyricCache();
  object.artworkUrls = reader.readStringList(offsets[0]);
  object.cacheId = reader.readString(offsets[1]);
  object.composer = reader.readStringOrNull(offsets[2]);
  object.contributor = reader.readStringOrNull(offsets[3]);
  object.copyright = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.isPureMusic = reader.readBool(offsets[5]);
  object.isRichSync = reader.readBool(offsets[6]);
  object.isSynced = reader.readBool(offsets[7]);
  object.lyrics =
      reader.readObjectList<LyricItem>(
        offsets[8],
        LyricItemSchema.deserialize,
        allOffsets,
        LyricItem(),
      ) ??
      [];
  object.source = reader.readString(offsets[9]);
  object.sourceProvider = reader.readStringOrNull(offsets[10]);
  object.writtenBy = reader.readStringOrNull(offsets[11]);
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
      return (reader.readStringList(offset)) as P;
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
              [])
          as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
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

  List<Id> putAllByCacheIdSync(
    List<LyricCache> objects, {
    bool saveLinks = true,
  }) {
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
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
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

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
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

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> cacheIdEqualTo(
    String cacheId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'cacheId', value: [cacheId]),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterWhereClause> cacheIdNotEqualTo(
    String cacheId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [],
                upper: [cacheId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [cacheId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [cacheId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [],
                upper: [cacheId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LyricCacheQueryFilter
    on QueryBuilder<LyricCache, LyricCache, QFilterCondition> {
  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'artworkUrls'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'artworkUrls'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'artworkUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'artworkUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'artworkUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'artworkUrls',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'artworkUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'artworkUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'artworkUrls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'artworkUrls',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'artworkUrls', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'artworkUrls', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'artworkUrls', length, true, length, true);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'artworkUrls', 0, true, 0, true);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'artworkUrls', 0, false, 999999, true);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'artworkUrls', 0, true, length, include);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'artworkUrls', length, include, 999999, true);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  artworkUrlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'artworkUrls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  cacheIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cacheId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cacheId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> cacheIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cacheId', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  cacheIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cacheId', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'composer'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  composerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'composer'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'composer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  composerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'composer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'composer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'composer',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  composerStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'composer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'composer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'composer',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> composerMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'composer',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  composerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'composer', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  composerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'composer', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contributor'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contributor'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contributor',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contributor',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contributor', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  contributorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contributor', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  copyrightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'copyright'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  copyrightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'copyright'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'copyright',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  copyrightGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'copyright',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'copyright',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'copyright',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  copyrightStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'copyright',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'copyright',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'copyright',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> copyrightMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'copyright',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  copyrightIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'copyright', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  copyrightIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'copyright', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  isPureMusicEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isPureMusic', value: value),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> isRichSyncEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isRichSync', value: value),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> isSyncedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isSynced', value: value),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  lyricsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', length, true, length, true);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> lyricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', 0, true, 0, true);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  lyricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', 0, false, 999999, true);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  lyricsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', 0, true, length, include);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  lyricsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', length, include, 999999, true);
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
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceProvider'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceProvider'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceProvider',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceProvider',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceProvider', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  sourceProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceProvider', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  writtenByIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'writtenBy'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  writtenByIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'writtenBy'),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'writtenBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  writtenByGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'writtenBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'writtenBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'writtenBy',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  writtenByStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'writtenBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'writtenBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'writtenBy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> writtenByMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'writtenBy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  writtenByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'writtenBy', value: ''),
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition>
  writtenByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'writtenBy', value: ''),
      );
    });
  }
}

extension LyricCacheQueryObject
    on QueryBuilder<LyricCache, LyricCache, QFilterCondition> {
  QueryBuilder<LyricCache, LyricCache, QAfterFilterCondition> lyricsElement(
    FilterQuery<LyricItem> q,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'lyrics');
    });
  }
}

extension LyricCacheQueryLinks
    on QueryBuilder<LyricCache, LyricCache, QFilterCondition> {}

extension LyricCacheQuerySortBy
    on QueryBuilder<LyricCache, LyricCache, QSortBy> {
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

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> sortBySourceProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy>
  sortBySourceProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.desc);
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

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy> thenBySourceProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.asc);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QAfterSortBy>
  thenBySourceProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.desc);
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
  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByArtworkUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'artworkUrls');
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByCacheId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByComposer({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'composer', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByContributor({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contributor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByCopyright({
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctBySourceProvider({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceProvider',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LyricCache, LyricCache, QDistinct> distinctByWrittenBy({
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<LyricCache, List<String>?, QQueryOperations>
  artworkUrlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'artworkUrls');
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

  QueryBuilder<LyricCache, String?, QQueryOperations> sourceProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceProvider');
    });
  }

  QueryBuilder<LyricCache, String?, QQueryOperations> writtenByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'writtenBy');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTranslationCacheCollection on Isar {
  IsarCollection<TranslationCache> get translationCaches => this.collection();
}

const TranslationCacheSchema = CollectionSchema(
  name: r'TranslationCache',
  id: 6214070051513875310,
  properties: {
    r'cacheId': PropertySchema(id: 0, name: r'cacheId', type: IsarType.string),
    r'language': PropertySchema(
      id: 1,
      name: r'language',
      type: IsarType.string,
    ),
    r'lyrics': PropertySchema(
      id: 2,
      name: r'lyrics',
      type: IsarType.objectList,

      target: r'TranslationItem',
    ),
    r'rawTranslation': PropertySchema(
      id: 3,
      name: r'rawTranslation',
      type: IsarType.objectList,

      target: r'RawTranslationPair',
    ),
    r'source': PropertySchema(id: 4, name: r'source', type: IsarType.string),
    r'sourceProvider': PropertySchema(
      id: 5,
      name: r'sourceProvider',
      type: IsarType.string,
    ),
    r'translationContributor': PropertySchema(
      id: 6,
      name: r'translationContributor',
      type: IsarType.string,
    ),
    r'translationProvider': PropertySchema(
      id: 7,
      name: r'translationProvider',
      type: IsarType.string,
    ),
  },

  estimateSize: _translationCacheEstimateSize,
  serialize: _translationCacheSerialize,
  deserialize: _translationCacheDeserialize,
  deserializeProp: _translationCacheDeserializeProp,
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
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {
    r'TranslationItem': TranslationItemSchema,
    r'RawTranslationPair': RawTranslationPairSchema,
  },

  getId: _translationCacheGetId,
  getLinks: _translationCacheGetLinks,
  attach: _translationCacheAttach,
  version: '3.3.2',
);

int _translationCacheEstimateSize(
  TranslationCache object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cacheId.length * 3;
  bytesCount += 3 + object.language.length * 3;
  bytesCount += 3 + object.lyrics.length * 3;
  {
    final offsets = allOffsets[TranslationItem]!;
    for (var i = 0; i < object.lyrics.length; i++) {
      final value = object.lyrics[i];
      bytesCount += TranslationItemSchema.estimateSize(
        value,
        offsets,
        allOffsets,
      );
    }
  }
  {
    final list = object.rawTranslation;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[RawTranslationPair]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += RawTranslationPairSchema.estimateSize(
            value,
            offsets,
            allOffsets,
          );
        }
      }
    }
  }
  bytesCount += 3 + object.source.length * 3;
  {
    final value = object.sourceProvider;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.translationContributor;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.translationProvider.length * 3;
  return bytesCount;
}

void _translationCacheSerialize(
  TranslationCache object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cacheId);
  writer.writeString(offsets[1], object.language);
  writer.writeObjectList<TranslationItem>(
    offsets[2],
    allOffsets,
    TranslationItemSchema.serialize,
    object.lyrics,
  );
  writer.writeObjectList<RawTranslationPair>(
    offsets[3],
    allOffsets,
    RawTranslationPairSchema.serialize,
    object.rawTranslation,
  );
  writer.writeString(offsets[4], object.source);
  writer.writeString(offsets[5], object.sourceProvider);
  writer.writeString(offsets[6], object.translationContributor);
  writer.writeString(offsets[7], object.translationProvider);
}

TranslationCache _translationCacheDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TranslationCache();
  object.cacheId = reader.readString(offsets[0]);
  object.id = id;
  object.language = reader.readString(offsets[1]);
  object.lyrics =
      reader.readObjectList<TranslationItem>(
        offsets[2],
        TranslationItemSchema.deserialize,
        allOffsets,
        TranslationItem(),
      ) ??
      [];
  object.rawTranslation = reader.readObjectList<RawTranslationPair>(
    offsets[3],
    RawTranslationPairSchema.deserialize,
    allOffsets,
    RawTranslationPair(),
  );
  object.source = reader.readString(offsets[4]);
  object.sourceProvider = reader.readStringOrNull(offsets[5]);
  object.translationContributor = reader.readStringOrNull(offsets[6]);
  object.translationProvider = reader.readString(offsets[7]);
  return object;
}

P _translationCacheDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readObjectList<TranslationItem>(
                offset,
                TranslationItemSchema.deserialize,
                allOffsets,
                TranslationItem(),
              ) ??
              [])
          as P;
    case 3:
      return (reader.readObjectList<RawTranslationPair>(
            offset,
            RawTranslationPairSchema.deserialize,
            allOffsets,
            RawTranslationPair(),
          ))
          as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _translationCacheGetId(TranslationCache object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _translationCacheGetLinks(TranslationCache object) {
  return [];
}

void _translationCacheAttach(
  IsarCollection<dynamic> col,
  Id id,
  TranslationCache object,
) {
  object.id = id;
}

extension TranslationCacheByIndex on IsarCollection<TranslationCache> {
  Future<TranslationCache?> getByCacheId(String cacheId) {
    return getByIndex(r'cacheId', [cacheId]);
  }

  TranslationCache? getByCacheIdSync(String cacheId) {
    return getByIndexSync(r'cacheId', [cacheId]);
  }

  Future<bool> deleteByCacheId(String cacheId) {
    return deleteByIndex(r'cacheId', [cacheId]);
  }

  bool deleteByCacheIdSync(String cacheId) {
    return deleteByIndexSync(r'cacheId', [cacheId]);
  }

  Future<List<TranslationCache?>> getAllByCacheId(List<String> cacheIdValues) {
    final values = cacheIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'cacheId', values);
  }

  List<TranslationCache?> getAllByCacheIdSync(List<String> cacheIdValues) {
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

  Future<Id> putByCacheId(TranslationCache object) {
    return putByIndex(r'cacheId', object);
  }

  Id putByCacheIdSync(TranslationCache object, {bool saveLinks = true}) {
    return putByIndexSync(r'cacheId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCacheId(List<TranslationCache> objects) {
    return putAllByIndex(r'cacheId', objects);
  }

  List<Id> putAllByCacheIdSync(
    List<TranslationCache> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'cacheId', objects, saveLinks: saveLinks);
  }
}

extension TranslationCacheQueryWhereSort
    on QueryBuilder<TranslationCache, TranslationCache, QWhere> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TranslationCacheQueryWhere
    on QueryBuilder<TranslationCache, TranslationCache, QWhereClause> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
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

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause> idBetween(
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

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
  cacheIdEqualTo(String cacheId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'cacheId', value: [cacheId]),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterWhereClause>
  cacheIdNotEqualTo(String cacheId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [],
                upper: [cacheId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [cacheId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [cacheId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'cacheId',
                lower: [],
                upper: [cacheId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension TranslationCacheQueryFilter
    on QueryBuilder<TranslationCache, TranslationCache, QFilterCondition> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cacheId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cacheId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cacheId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cacheId', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  cacheIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cacheId', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
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

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
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

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
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

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'language',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'language',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'language',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'language',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'language',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'language',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'language',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'language',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'language', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  languageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'language', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  lyricsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', length, true, length, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  lyricsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', 0, true, 0, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  lyricsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', 0, false, 999999, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  lyricsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', 0, true, length, include);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  lyricsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'lyrics', length, include, 999999, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
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

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rawTranslation'),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rawTranslation'),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'rawTranslation', length, true, length, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'rawTranslation', 0, true, 0, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'rawTranslation', 0, false, 999999, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'rawTranslation', 0, true, length, include);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'rawTranslation', length, include, 999999, true);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rawTranslation',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceProvider'),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceProvider'),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceProvider',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceProvider',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceProvider', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  sourceProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceProvider', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'translationContributor'),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'translationContributor'),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'translationContributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'translationContributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'translationContributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'translationContributor',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'translationContributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'translationContributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'translationContributor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'translationContributor',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'translationContributor', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationContributorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'translationContributor',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'translationProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'translationProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'translationProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'translationProvider',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'translationProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'translationProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'translationProvider',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'translationProvider',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'translationProvider', value: ''),
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  translationProviderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'translationProvider',
          value: '',
        ),
      );
    });
  }
}

extension TranslationCacheQueryObject
    on QueryBuilder<TranslationCache, TranslationCache, QFilterCondition> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  lyricsElement(FilterQuery<TranslationItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'lyrics');
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterFilterCondition>
  rawTranslationElement(FilterQuery<RawTranslationPair> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'rawTranslation');
    });
  }
}

extension TranslationCacheQueryLinks
    on QueryBuilder<TranslationCache, TranslationCache, QFilterCondition> {}

extension TranslationCacheQuerySortBy
    on QueryBuilder<TranslationCache, TranslationCache, QSortBy> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByCacheId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByCacheIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortBySourceProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortBySourceProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByTranslationContributor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByTranslationContributorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByTranslationProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  sortByTranslationProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.desc);
    });
  }
}

extension TranslationCacheQuerySortThenBy
    on QueryBuilder<TranslationCache, TranslationCache, QSortThenBy> {
  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByCacheId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByCacheIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheId', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByLanguage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByLanguageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'language', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenBySourceProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenBySourceProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceProvider', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByTranslationContributor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByTranslationContributorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationContributor', Sort.desc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByTranslationProvider() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.asc);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QAfterSortBy>
  thenByTranslationProviderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'translationProvider', Sort.desc);
    });
  }
}

extension TranslationCacheQueryWhereDistinct
    on QueryBuilder<TranslationCache, TranslationCache, QDistinct> {
  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
  distinctByCacheId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
  distinctByLanguage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'language', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct> distinctBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
  distinctBySourceProvider({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceProvider',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
  distinctByTranslationContributor({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'translationContributor',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<TranslationCache, TranslationCache, QDistinct>
  distinctByTranslationProvider({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'translationProvider',
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension TranslationCacheQueryProperty
    on QueryBuilder<TranslationCache, TranslationCache, QQueryProperty> {
  QueryBuilder<TranslationCache, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations> cacheIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheId');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations> languageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'language');
    });
  }

  QueryBuilder<TranslationCache, List<TranslationItem>, QQueryOperations>
  lyricsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lyrics');
    });
  }

  QueryBuilder<TranslationCache, List<RawTranslationPair>?, QQueryOperations>
  rawTranslationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawTranslation');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<TranslationCache, String?, QQueryOperations>
  sourceProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceProvider');
    });
  }

  QueryBuilder<TranslationCache, String?, QQueryOperations>
  translationContributorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translationContributor');
    });
  }

  QueryBuilder<TranslationCache, String, QQueryOperations>
  translationProviderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'translationProvider');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const RawTranslationPairSchema = Schema(
  name: r'RawTranslationPair',
  id: -2519904812350907104,
  properties: {
    r'original': PropertySchema(
      id: 0,
      name: r'original',
      type: IsarType.string,
    ),
    r'translated': PropertySchema(
      id: 1,
      name: r'translated',
      type: IsarType.string,
    ),
  },

  estimateSize: _rawTranslationPairEstimateSize,
  serialize: _rawTranslationPairSerialize,
  deserialize: _rawTranslationPairDeserialize,
  deserializeProp: _rawTranslationPairDeserializeProp,
);

int _rawTranslationPairEstimateSize(
  RawTranslationPair object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.original;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.translated;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _rawTranslationPairSerialize(
  RawTranslationPair object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.original);
  writer.writeString(offsets[1], object.translated);
}

RawTranslationPair _rawTranslationPairDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RawTranslationPair();
  object.original = reader.readStringOrNull(offsets[0]);
  object.translated = reader.readStringOrNull(offsets[1]);
  return object;
}

P _rawTranslationPairDeserializeProp<P>(
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension RawTranslationPairQueryFilter
    on QueryBuilder<RawTranslationPair, RawTranslationPair, QFilterCondition> {
  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'original'),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'original'),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'original',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'original',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'original',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'original', value: ''),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  originalIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'original', value: ''),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'translated'),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'translated'),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'translated',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'translated',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'translated',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'translated',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'translated',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'translated',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'translated',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'translated',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'translated', value: ''),
      );
    });
  }

  QueryBuilder<RawTranslationPair, RawTranslationPair, QAfterFilterCondition>
  translatedIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'translated', value: ''),
      );
    });
  }
}

extension RawTranslationPairQueryObject
    on QueryBuilder<RawTranslationPair, RawTranslationPair, QFilterCondition> {}

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
    r'text': PropertySchema(id: 3, name: r'text', type: IsarType.string),
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
            value,
            offsets,
            allOffsets,
          );
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
          ))
          as P;
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
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'endTimeMs'),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  endTimeMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'endTimeMs'),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> endTimeMsEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endTimeMs', value: value),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  endTimeMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> endTimeMsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> endTimeMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endTimeMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  inlinePartsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'inlineParts'),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  inlinePartsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'inlineParts'),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  inlinePartsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'inlineParts', length, true, length, true);
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  inlinePartsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'inlineParts', 0, true, 0, true);
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  inlinePartsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'inlineParts', 0, false, 999999, true);
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  inlinePartsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'inlineParts', 0, true, length, include);
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  inlinePartsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'inlineParts', length, include, 999999, true);
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
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startTimeMs', value: value),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition>
  startTimeMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> startTimeMsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> startTimeMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startTimeMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }
}

extension LyricItemQueryObject
    on QueryBuilder<LyricItem, LyricItem, QFilterCondition> {
  QueryBuilder<LyricItem, LyricItem, QAfterFilterCondition> inlinePartsElement(
    FilterQuery<LyricItemInlinePart> q,
  ) {
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
    r'text': PropertySchema(id: 2, name: r'text', type: IsarType.string),
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

extension LyricItemInlinePartQueryFilter
    on
        QueryBuilder<
          LyricItemInlinePart,
          LyricItemInlinePart,
          QFilterCondition
        > {
  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  endTimeMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endTimeMs', value: value),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  endTimeMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  endTimeMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endTimeMs',
          value: value,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endTimeMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  startTimeMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startTimeMs', value: value),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  startTimeMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  startTimeMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startTimeMs',
          value: value,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startTimeMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
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
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<LyricItemInlinePart, LyricItemInlinePart, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }
}

extension LyricItemInlinePartQueryObject
    on
        QueryBuilder<
          LyricItemInlinePart,
          LyricItemInlinePart,
          QFilterCondition
        > {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TranslationItemSchema = Schema(
  name: r'TranslationItem',
  id: -7238149442883127455,
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
    r'text': PropertySchema(id: 2, name: r'text', type: IsarType.string),
  },

  estimateSize: _translationItemEstimateSize,
  serialize: _translationItemSerialize,
  deserialize: _translationItemDeserialize,
  deserializeProp: _translationItemDeserializeProp,
);

int _translationItemEstimateSize(
  TranslationItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.text.length * 3;
  return bytesCount;
}

void _translationItemSerialize(
  TranslationItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.endTimeMs);
  writer.writeLong(offsets[1], object.startTimeMs);
  writer.writeString(offsets[2], object.text);
}

TranslationItem _translationItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TranslationItem();
  object.endTimeMs = reader.readLongOrNull(offsets[0]);
  object.startTimeMs = reader.readLong(offsets[1]);
  object.text = reader.readString(offsets[2]);
  return object;
}

P _translationItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TranslationItemQueryFilter
    on QueryBuilder<TranslationItem, TranslationItem, QFilterCondition> {
  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  endTimeMsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'endTimeMs'),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  endTimeMsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'endTimeMs'),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  endTimeMsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'endTimeMs', value: value),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  endTimeMsGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'endTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  endTimeMsLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'endTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  endTimeMsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'endTimeMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  startTimeMsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startTimeMs', value: value),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  startTimeMsGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  startTimeMsLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startTimeMs',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  startTimeMsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startTimeMs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'text',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'text',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'text',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'text', value: ''),
      );
    });
  }

  QueryBuilder<TranslationItem, TranslationItem, QAfterFilterCondition>
  textIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'text', value: ''),
      );
    });
  }
}

extension TranslationItemQueryObject
    on QueryBuilder<TranslationItem, TranslationItem, QFilterCondition> {}
