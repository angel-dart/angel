library angel_orm.generator.models.author;

import 'package:angel_framework/common.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'author.g.dart';

@serializable
@orm
class _Author extends Model {
  @Column(length: 255, index: IndexType.UNIQUE, defaultValue: 'Tobe Osakwe')
  String name;
}
