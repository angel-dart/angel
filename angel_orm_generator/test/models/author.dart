library angel_orm.generator.models.author;

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';

part 'author.g.dart';

part 'author.serializer.g.dart';

@serializable
@postgreSqlOrm
class _Author extends Model {
  @Column(length: 255, indexType: IndexType.unique, defaultValue: 'Tobe Osakwe')
  String name;
}
