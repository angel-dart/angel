import 'dart:async';
import 'package:io/ansi.dart';
import 'all.dart' as hm;

main() async {
  var zone = Zone.current.fork(
    specification: ZoneSpecification(print: (self, parent, zone, line) {
      if (line == 'null') {
        parent.print(zone, cyan.wrap(StackTrace.current.toString()));
      }
    }),
  );
  return await zone.run(hm.main);
}
