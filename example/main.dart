import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:logging/logging.dart';
import 'package:pretty_logging/pretty_logging.dart';

main() async {
  // Logging set up/boilerplate
  Logger.root.onRecord.listen(prettyLog);

  // Create our server.
  var app = Angel(
    logger: Logger('angel'),
    reflector: MirrorsReflector(),
  );

  // Index route. Returns JSON.
  app.get('/', (req, res) => 'Welcome to Angel!');

  // Accepts a URL like /greet/foo or /greet/bob.
  app.get(
    '/greet/:name',
    (req, res) {
      var name = req.params['name'];
      res
        ..write('Hello, $name!')
        ..close();
    },
  );

  // Pattern matching - only call this handler if the query value of `name` equals 'emoji'.
  app.get(
    '/greet',
    ioc((@Query('name', match: 'emoji') String name) => '😇🔥🔥🔥'),
  );

  // Handle any other query value of `name`.
  app.get(
    '/greet',
    ioc((@Query('name') String name) => 'Hello, $name!'),
  );

  // Simple fallback to throw a 404 on unknown paths.
  app.fallback((req, res) {
    throw AngelHttpException.notFound(
      message: 'Unknown path: "${req.uri.path}"',
    );
  });

  var http = AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening at $url');
  print('Visit these pages to see Angel in action:');
  print('* $url/greet/bob');
  print('* $url/greet/?name=emoji');
  print('* $url/greet/?name=jack');
  print('* $url/nonexistent_page');
}
