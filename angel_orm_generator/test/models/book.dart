library angel_orm.generator.models.book;

import 'package:angel_framework/common.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'author.dart';
part 'book.g.dart';

@serializable
@orm
class _Book extends Model {
  @belongsTo
  Author author;
  int authorId;
  String name;
}
