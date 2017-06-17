library angel_orm.test.models.car;

import 'package:angel_framework/common.dart';
import 'package:angel_orm/angel_orm.dart' as orm;
import 'package:angel_serialize/angel_serialize.dart';
part 'car.g.dart';

@serializable
@orm.model
class _Car extends Model {
  @override
  String id;

  @override
  @Alias('created_at')
  DateTime createdAt;

  @override
  @Alias('updated_at')
  DateTime updatedAt;
}