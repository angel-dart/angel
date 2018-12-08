library angel_orm_generator.test.models.leg;

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'foot.dart';
part 'leg.g.dart';

@serializable
@orm
class _Leg extends Model {
  @hasOne
  Foot foot;

  String name;
}
