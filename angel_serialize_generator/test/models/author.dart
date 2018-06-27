library angel_serialize.test.models.author;

import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'book.dart';

part 'author.g.dart';

part 'author.serializer.g.dart';

@serializable
abstract class _Author extends Model {
  @required
  String get name;

  String get customMethod => 'hey!';

  @Required('Custom message for missing `age`')
  int get age;

  List<Book> get books;

  Book get newestBook;

  @exclude
  String get secret;

  @Exclude(canDeserialize: true)
  String get obscured;
}

@Serializable(serializers: Serializers.all)
abstract class _Library extends Model {
  Map<String, Book> get collection;
}

@Serializable(serializers: Serializers.all)
abstract class _Bookmark extends Model {
  @exclude
  final Book book;

  List<int> get history;

  @required
  int get page;

  String get comment;

  _Bookmark(this.book);
}
