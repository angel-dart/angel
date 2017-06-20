library angel_serialize.test.models.book;

import 'package:angel_framework/common.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'book.g.dart';

@serializable
abstract class _Book extends Model {
  String author, title, description;
  int pageCount;
}

@serializable
abstract class _Author extends Model {
  String name;
  int age;
  List<_Book> books;
  _Book newestBook;
  @exclude
  String secret;
}

@serializable
abstract class _Library extends Model {
  Map<String, _Book> collection;
}