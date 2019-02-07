import 'dart:io';
import 'package:angel_hot/angel_hot.dart';
import 'server.dart';

main() async {
  var hot = new HotReloader(createServer, [
    new Directory('src'),
    new Directory('src'),
    'server.dart',
    // Also allowed: Platform.script,
    Uri.parse('package:angel_hot/angel_hot.dart')
  ]);
  await hot.startServer('127.0.0.1', 3000);
}
