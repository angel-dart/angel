// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'human.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Human extends _Human {
  Human(
      {this.id,
      this.name,
      List<Episode> appearsIn,
      List<Character> friends,
      this.totalCredits,
      this.createdAt,
      this.updatedAt})
      : this.appearsIn = new List.unmodifiable(appearsIn ?? []),
        this.friends = new List.unmodifiable(friends ?? []);

  @override
  final String id;

  @override
  final String name;

  @override
  final List<Episode> appearsIn;

  @override
  final List<Character> friends;

  @override
  final int totalCredits;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Human copyWith(
      {String id,
      String name,
      List<Episode> appearsIn,
      List<Character> friends,
      int totalCredits,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Human(
        id: id ?? this.id,
        name: name ?? this.name,
        appearsIn: appearsIn ?? this.appearsIn,
        friends: friends ?? this.friends,
        totalCredits: totalCredits ?? this.totalCredits,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Human &&
        other.id == id &&
        other.name == name &&
        const ListEquality<Episode>(const DefaultEquality<Episode>())
            .equals(other.appearsIn, appearsIn) &&
        const ListEquality<Character>(const DefaultEquality<Character>())
            .equals(other.friends, friends) &&
        other.totalCredits == totalCredits &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects(
        [id, name, appearsIn, friends, totalCredits, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return HumanSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class HumanSerializer {
  static Human fromMap(Map map) {
    return new Human(
        id: map['id'] as String,
        name: map['name'] as String,
        appearsIn: map['appears_in'] is Iterable
            ? (map['appears_in'] as Iterable).cast<Episode>().toList()
            : null,
        friends: map['friends'] is Iterable
            ? (map['friends'] as Iterable).cast<Character>().toList()
            : null,
        totalCredits: map['total_credits'] as int,
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

  static Map<String, dynamic> toMap(_Human model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'name': model.name,
      'appears_in': model.appearsIn,
      'friends': model.friends,
      'total_credits': model.totalCredits,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class HumanFields {
  static const List<String> allFields = <String>[
    id,
    name,
    appearsIn,
    friends,
    totalCredits,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String name = 'name';

  static const String appearsIn = 'appears_in';

  static const String friends = 'friends';

  static const String totalCredits = 'total_credits';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

// **************************************************************************
// _GraphQLGenerator
// **************************************************************************

/// Auto-generated from [Human].
final GraphQLObjectType humanGraphQLType =
    objectType('Human', isInterface: false, interfaces: [
  characterGraphQLType
], fields: [
  field('id', graphQLString),
  field('name', graphQLString),
  field('appears_in', listOf(episodeGraphQLType)),
  field('friends', listOf(characterGraphQLType)),
  field('total_credits', graphQLInt),
  field('created_at', graphQLDate),
  field('updated_at', graphQLDate),
  field('idAsInt', graphQLInt)
]);
