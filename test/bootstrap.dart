import 'dart:io';
import 'package:rethinkdb_driver2/rethinkdb_driver2.dart';

main() async {
  var r = new Rethinkdb();
  r.connect().then((conn) {
    r.tableCreate('todos').run(conn);
    print('Done');
    exit(0);
  });
}
