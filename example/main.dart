import 'package:angel_framework/angel_framework.dart';

main() async {
  var app = new Angel();

  app.get('/', () => 'Welcome to Angel!');

  app.get('/greet/:name', (String name) => 'Hello, $name!');

  app.use((RequestContext req) async {
    throw new AngelHttpException.notFound(
      message: 'Unknown path: "${req.uri.path}"',
    );
  });

  var http = new AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
