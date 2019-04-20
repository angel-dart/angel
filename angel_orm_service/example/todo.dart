import 'package:angel_migration/angel_migration.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:angel_orm/angel_orm.dart';
part 'todo.g.dart';

@serializable
@orm
abstract class _Todo extends Model {
  @notNull
  String get text;

  @DefaultsTo(false)
  bool isComplete;
}
