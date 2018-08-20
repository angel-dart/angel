import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';

main() async {
  var app = new Angel(reflector: MirrorsReflector());

  app.viewGenerator = (name, [data]) async =>
      'View generator invoked with name $name and data: $data';

  // Index route. Returns JSON.
  app.get('/', (ResponseContext res) => res.render('index', {'foo': 'bar'}));

  var http = new AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening at $url');
}
