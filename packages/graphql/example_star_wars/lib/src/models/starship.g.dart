// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'starship.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Starship extends _Starship {
  Starship({this.id, this.name, this.length, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String name;

  @override
  final int length;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Starship copyWith(
      {String id,
      String name,
      int length,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Starship(
        id: id ?? this.id,
        name: name ?? this.name,
        length: length ?? this.length,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Starship &&
        other.id == id &&
        other.name == name &&
        other.length == length &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, name, length, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return StarshipSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class StarshipSerializer {
  static Starship fromMap(Map map) {
    return new Starship(
        id: map['id'] as String,
        name: map['name'] as String,
        length: map['length'] as int,
        createdAt: map['created_at'] != null
            ? (map['created_at'] is DateTime
                ? (map['created_at'] as DateTime)
                : DateTime.parse(map['created_at'].toString()))
            : null,
        updatedAt: map['updated_at'] != null
            ? (map['updated_at'] is DateTime
                ? (map['updated_at'] as DateTime)
                : DateTime.parse(map['updated_at'].toString()))
            : null);
  }

  static Map<String, dynamic> toMap(_Starship model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'name': model.name,
      'length': model.length,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class StarshipFields {
  static const List<String> allFields = <String>[
    id,
    name,
    length,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String name = 'name';

  static const String length = 'length';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

// **************************************************************************
// _GraphQLGenerator
// **************************************************************************

/// Auto-generated from [Starship].
final GraphQLObjectType starshipGraphQLType =
    objectType('Starship', isInterface: false, interfaces: [], fields: [
  field('id', graphQLString),
  field('name', graphQLString),
  field('length', graphQLInt),
  field('created_at', graphQLDate),
  field('updated_at', graphQLDate),
  field('idAsInt', graphQLInt)
]);
