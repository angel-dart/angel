library angel_orm.generator.models.book;

import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'book.g.dart';

@serializable
@orm
class _Book extends Model {
  @BelongsTo(joinType: JoinType.inner)
  _Author author;

  @BelongsTo(localKey: "partner_author_id", joinType: JoinType.inner)
  _Author partnerAuthor;

  String name;
}

@serializable
@orm
abstract class _Author extends Model {
  @Column(length: 255, indexType: IndexType.unique)
  @SerializableField(defaultValue: 'Tobe Osakwe')
  String get name;
}
