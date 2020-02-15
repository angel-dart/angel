library angel_orm_generator.test.models.tree;

import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:collection/collection.dart';
part 'tree.g.dart';

@serializable
@orm
class _Tree extends Model {
  @Column(indexType: IndexType.unique, type: ColumnType.smallInt)
  int rings;

  @hasMany
  List<_Fruit> fruits;
}

@serializable
@orm
class _Fruit extends Model {
  int treeId;
  String commonName;
}
