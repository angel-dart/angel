import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'custom_expr.g.dart';

@serializable
@orm
class _Numbers extends Model {
  @Column(expression: 'SELECT 2')
  int two;
}

@serializable
@orm
class _Alphabet extends Model {
  String value;

  @belongsTo
  _Numbers numbers;
}
