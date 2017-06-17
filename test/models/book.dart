library angel_serialize.test.models.book;

import 'package:angel_framework/common.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'book.g.dart';

@serializable
abstract class _Book extends Model {
  @override
  String id;
  String author, title, description;

  @Alias('page_count')
  int pageCount;

  @override
  DateTime createdAt, updatedAt;
}

@serializable
abstract class _Author extends Model {
  @override
  String id;

  String name;

  int age;

  @override
  DateTime createdAt, updatedAt;

  List<_Book> books;

  @Alias('newest_book')
  _Book newestBook;

  @exclude
  String secret;
}

@serializable
abstract class _Library extends Model {
  @override
  String id;

  @override
  DateTime createdAt, updatedAt;

  Map<String, _Book> collection;
}