// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'droid.dart';

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Droid extends _Droid {
  Droid(
      {this.id,
      this.name,
      List<Episode> appearsIn,
      List<Character> friends,
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
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Droid copyWith(
      {String id,
      String name,
      List<Episode> appearsIn,
      List<Character> friends,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Droid(
        id: id ?? this.id,
        name: name ?? this.name,
        appearsIn: appearsIn ?? this.appearsIn,
        friends: friends ?? this.friends,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Droid &&
        other.id == id &&
        other.name == name &&
        const ListEquality<Episode>(const DefaultEquality<Episode>())
            .equals(other.appearsIn, appearsIn) &&
        const ListEquality<Character>(const DefaultEquality<Character>())
            .equals(other.friends, friends) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([id, name, appearsIn, friends, createdAt, updatedAt]);
  }

  Map<String, dynamic> toJson() {
    return DroidSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class DroidSerializer {
  static Droid fromMap(Map map) {
    return new Droid(
        id: map['id'] as String,
        name: map['name'] as String,
        appearsIn: map['appears_in'] is Iterable
            ? (map['appears_in'] as Iterable).cast<Episode>().toList()
            : null,
        friends: map['friends'] is Iterable
            ? (map['friends'] as Iterable).cast<Character>().toList()
            : null,
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

  static Map<String, dynamic> toMap(_Droid model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'name': model.name,
      'appears_in': model.appearsIn,
      'friends': model.friends,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class DroidFields {
  static const List<String> allFields = <String>[
    id,
    name,
    appearsIn,
    friends,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String name = 'name';

  static const String appearsIn = 'appears_in';

  static const String friends = 'friends';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}

// **************************************************************************
// _GraphQLGenerator
// **************************************************************************

/// Auto-generated from [Droid].
final GraphQLObjectType droidGraphQLType = objectType('Droid',
    isInterface: false,
    description: 'Beep! Boop!',
    interfaces: [
      characterGraphQLType
    ],
    fields: [
      field('id', graphQLString),
      field('name', graphQLString),
      field('appears_in', listOf(episodeGraphQLType),
          description: 'The list of episodes this droid appears in.'),
      field('friends', listOf(characterGraphQLType),
          description:
              'Doc comments automatically become GraphQL descriptions.'),
      field('created_at', graphQLDate),
      field('updated_at', graphQLDate),
      field('idAsInt', graphQLInt)
    ]);
