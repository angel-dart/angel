library angel_orm_generator.test.models.fruit;

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'fruit.g.dart';
part 'fruit.serializer.g.dart';

@serializable
@postgreSqlOrm
class _Fruit extends Model {
  int treeId;
  String commonName;
}