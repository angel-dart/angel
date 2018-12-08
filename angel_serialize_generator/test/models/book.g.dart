// GENERATED CODE - DO NOT MODIFY BY HAND

part of angel_serialize.test.models.book;

// **************************************************************************
// JsonModelGenerator
// **************************************************************************

@generatedSerializable
class Book extends _Book {
  Book(
      {this.id,
      this.author,
      this.title,
      this.description,
      this.pageCount,
      List<double> notModels,
      this.camelCaseString,
      this.createdAt,
      this.updatedAt})
      : this.notModels = new List.unmodifiable(notModels ?? []);

  @override
  final String id;

  @override
  final String author;

  @override
  final String title;

  @override
  final String description;

  @override
  final int pageCount;

  @override
  final List<double> notModels;

  @override
  final String camelCaseString;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  Book copyWith(
      {String id,
      String author,
      String title,
      String description,
      int pageCount,
      List<double> notModels,
      String camelCaseString,
      DateTime createdAt,
      DateTime updatedAt}) {
    return new Book(
        id: id ?? this.id,
        author: author ?? this.author,
        title: title ?? this.title,
        description: description ?? this.description,
        pageCount: pageCount ?? this.pageCount,
        notModels: notModels ?? this.notModels,
        camelCaseString: camelCaseString ?? this.camelCaseString,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt);
  }

  bool operator ==(other) {
    return other is _Book &&
        other.id == id &&
        other.author == author &&
        other.title == title &&
        other.description == description &&
        other.pageCount == pageCount &&
        const ListEquality<double>(const DefaultEquality<double>())
            .equals(other.notModels, notModels) &&
        other.camelCaseString == camelCaseString &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return hashObjects([
      id,
      author,
      title,
      description,
      pageCount,
      notModels,
      camelCaseString,
      createdAt,
      updatedAt
    ]);
  }

  Map<String, dynamic> toJson() {
    return BookSerializer.toMap(this);
  }
}

// **************************************************************************
// SerializerGenerator
// **************************************************************************

abstract class BookSerializer {
  static Book fromMap(Map map) {
    return new Book(
        id: map['id'] as String,
        author: map['author'] as String,
        title: map['title'] as String,
        description: map['description'] as String,
        pageCount: map['page_count'] as int,
        notModels: map['not_models'] is Iterable
            ? (map['not_models'] as Iterable).cast<double>().toList()
            : null,
        camelCaseString: map['camelCase'] as String,
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

  static Map<String, dynamic> toMap(_Book model) {
    if (model == null) {
      return null;
    }
    return {
      'id': model.id,
      'author': model.author,
      'title': model.title,
      'description': model.description,
      'page_count': model.pageCount,
      'not_models': model.notModels,
      'camelCase': model.camelCaseString,
      'created_at': model.createdAt?.toIso8601String(),
      'updated_at': model.updatedAt?.toIso8601String()
    };
  }
}

abstract class BookFields {
  static const List<String> allFields = const <String>[
    id,
    author,
    title,
    description,
    pageCount,
    notModels,
    camelCaseString,
    createdAt,
    updatedAt
  ];

  static const String id = 'id';

  static const String author = 'author';

  static const String title = 'title';

  static const String description = 'description';

  static const String pageCount = 'page_count';

  static const String notModels = 'not_models';

  static const String camelCaseString = 'camelCase';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';
}
