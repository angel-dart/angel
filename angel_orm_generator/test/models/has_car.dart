import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'car.dart';
// part 'has_car.g.dart';

@orm
@serializable
abstract class _PackageJson extends Model {
  Car get car;
}
