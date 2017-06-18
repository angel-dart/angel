library angel_orm.test.models.car;

import 'package:angel_framework/common.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'tire.dart';
part 'car.g.dart';

@serializable
@orm
class _Car extends Model {
  String make;
  String description;
  bool familyFriendly;
  DateTime recalledAt;
  @hasMany
  List<Tire> tires;
}
