library angel_orm_generator.test.models.leg;

import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'leg.g.dart';

@serializable
@orm
class _Leg extends Model {
  @hasOne
  _Foot foot;

  String name;
}

@serializable
@Orm(tableName: 'feet')
class _Foot extends Model {
  int legId;

  double nToes;
}
