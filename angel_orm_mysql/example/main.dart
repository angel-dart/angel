import 'package:angel_migration/angel_migration.dart';
import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_orm_mysql/angel_orm_mysql.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'package:logging/logging.dart';
import 'package:sqljocky5/sqljocky.dart';
part 'main.g.dart';

main() async {
  hierarchicalLoggingEnabled = true;
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(print);

  var settings = ConnectionSettings(
      db: 'angel_orm_test', user: 'angel_orm_test', password: 'angel_orm_test');
  var connection = await MySqlConnection.connect(settings);
  var logger = Logger('angel_orm_mysql');
  var executor = MySqlExecutor(connection, logger: logger);

  var query = TodoQuery();
  query.values
    ..text = 'Clean your room!'
    ..isComplete = false;

  var todo = await query.insert(executor);
  print(todo.toJson());

  var query2 = TodoQuery()..where.id.equals(todo.idAsInt);
  var todo2 = await query2.getOne(executor);
  print(todo2.toJson());
  print(todo == todo2);
}

@serializable
@orm
abstract class _Todo extends Model {
  String get text;

  @DefaultsTo(false)
  bool isComplete;
}
