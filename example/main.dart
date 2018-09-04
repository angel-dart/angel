import 'dart:async';
import 'dart:isolate';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_production/angel_production.dart';

main(List<String> args) => new Runner('example', configureServer).run(args);

Future configureServer(Angel app) async {
  app.get('/', (req, res) => 'Hello, production world!');

  app.get('/crash', (req, res) {
    // We'll crash this instance deliberately, but the Runner will auto-respawn for us.
    new Timer(const Duration(seconds: 3), Isolate.current.kill);
    return 'Crashing in 3s...';
  });
}
