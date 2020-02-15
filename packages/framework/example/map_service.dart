import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:logging/logging.dart';

main() async {
  // Logging set up/boilerplate
  Logger.root.onRecord.listen(print);

  // Create our server.
  var app = Angel(
    logger: Logger('angel'),
    reflector: MirrorsReflector(),
  );

  // Create a RESTful service that manages an in-memory collection.
  app.use('/api/todos', MapService());

  var http = AngelHttp(app);
  await http.startServer('127.0.0.1', 0);
  print('Listening at ${http.uri}');
}
