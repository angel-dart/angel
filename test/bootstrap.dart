import 'package:rethinkdb_driver/rethinkdb_driver.dart';

main() async {
  var r = new Rethinkdb();
  var conn = await r.connect();
  await r.tableCreate('todos').run(conn);
}