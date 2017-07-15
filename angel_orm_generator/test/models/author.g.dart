// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_orm.generator.models.author;

// **************************************************************************
// Generator: JsonModelGenerator
// Target: class _Author
// **************************************************************************

class Author extends _Author {
  @override
  String id;

  @override
  String name;

  @override
  DateTime createdAt;

  @override
  DateTime updatedAt;

  Author({this.id, this.name, this.createdAt, this.updatedAt});

  factory Author.fromJson(Map data) {
    return new Author(
        id: data['id'],
        name: data['name'],
        createdAt: data['created_at'] is DateTime
            ? data['created_at']
            : (data['created_at'] is String
                ? DateTime.parse(data['created_at'])
                : null),
        updatedAt: data['updated_at'] is DateTime
            ? data['updated_at']
            : (data['updated_at'] is String
                ? DateTime.parse(data['updated_at'])
                : null));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt == null ? null : createdAt.toIso8601String(),
        'updated_at': updatedAt == null ? null : updatedAt.toIso8601String()
      };

  static Author parse(Map map) => new Author.fromJson(map);

  Author clone() {
    return new Author.fromJson(toJson());
  }
}
