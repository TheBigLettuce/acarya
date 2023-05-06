// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scroll_position.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScrollPositionCollection on Isar {
  IsarCollection<ScrollPosition> get scrollPositions => this.collection();
}

const ScrollPositionSchema = CollectionSchema(
  name: r'ScrollPosition',
  id: -180431956163981242,
  properties: {
    r'pos': PropertySchema(
      id: 0,
      name: r'pos',
      type: IsarType.double,
    )
  },
  estimateSize: _scrollPositionEstimateSize,
  serialize: _scrollPositionSerialize,
  deserialize: _scrollPositionDeserialize,
  deserializeProp: _scrollPositionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _scrollPositionGetId,
  getLinks: _scrollPositionGetLinks,
  attach: _scrollPositionAttach,
  version: '3.1.0+1',
);

int _scrollPositionEstimateSize(
  ScrollPosition object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _scrollPositionSerialize(
  ScrollPosition object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.pos);
}

ScrollPosition _scrollPositionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScrollPosition(
    reader.readDouble(offsets[0]),
  );
  object.id = id;
  return object;
}

P _scrollPositionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _scrollPositionGetId(ScrollPosition object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _scrollPositionGetLinks(ScrollPosition object) {
  return [];
}

void _scrollPositionAttach(
    IsarCollection<dynamic> col, Id id, ScrollPosition object) {
  object.id = id;
}

extension ScrollPositionQueryWhereSort
    on QueryBuilder<ScrollPosition, ScrollPosition, QWhere> {
  QueryBuilder<ScrollPosition, ScrollPosition, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ScrollPositionQueryWhere
    on QueryBuilder<ScrollPosition, ScrollPosition, QWhereClause> {
  QueryBuilder<ScrollPosition, ScrollPosition, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterWhereClause> idBetween(
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
}

extension ScrollPositionQueryFilter
    on QueryBuilder<ScrollPosition, ScrollPosition, QFilterCondition> {
  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition>
      posEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition>
      posGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition>
      posLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pos',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterFilterCondition>
      posBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pos',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ScrollPositionQueryObject
    on QueryBuilder<ScrollPosition, ScrollPosition, QFilterCondition> {}

extension ScrollPositionQueryLinks
    on QueryBuilder<ScrollPosition, ScrollPosition, QFilterCondition> {}

extension ScrollPositionQuerySortBy
    on QueryBuilder<ScrollPosition, ScrollPosition, QSortBy> {
  QueryBuilder<ScrollPosition, ScrollPosition, QAfterSortBy> sortByPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.asc);
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterSortBy> sortByPosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.desc);
    });
  }
}

extension ScrollPositionQuerySortThenBy
    on QueryBuilder<ScrollPosition, ScrollPosition, QSortThenBy> {
  QueryBuilder<ScrollPosition, ScrollPosition, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterSortBy> thenByPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.asc);
    });
  }

  QueryBuilder<ScrollPosition, ScrollPosition, QAfterSortBy> thenByPosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pos', Sort.desc);
    });
  }
}

extension ScrollPositionQueryWhereDistinct
    on QueryBuilder<ScrollPosition, ScrollPosition, QDistinct> {
  QueryBuilder<ScrollPosition, ScrollPosition, QDistinct> distinctByPos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pos');
    });
  }
}

extension ScrollPositionQueryProperty
    on QueryBuilder<ScrollPosition, ScrollPosition, QQueryProperty> {
  QueryBuilder<ScrollPosition, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ScrollPosition, double, QQueryOperations> posProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pos');
    });
  }
}
