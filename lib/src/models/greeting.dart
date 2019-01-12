import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:meta/meta.dart';
part 'greeting.g.dart';

@serializable
@orm
abstract class _Greeting extends Model {
  @SerializableField(isNullable: false)
  String get message;
}
