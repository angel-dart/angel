// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.author;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Author extends _Author {
  Author({this.id, this.name, this.createdAt, this.updatedAt});

  @override
  final String id;

  @override
  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Author copyWith(
      {String id, String name, DateTime createdAt, DateTime updatedAt}) {
    return new Author(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Author &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  Map<String, dynamic> toJson() {
    return AuthorSerializer.toMap(this);
  }
}
