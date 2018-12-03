library angel_orm.generator.models.book;

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'author.dart';
part 'book.g.dart';
part 'book.serializer.g.dart';

@serializable
@orm
class _Book extends Model {
  @belongsTo
  Author author;

  @BelongsTo(localKey: "partner_author_id")
  Author partnerAuthor;

  String name;
}
