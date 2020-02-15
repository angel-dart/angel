import 'package:angel_container/mirrors.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';

main() async {
  var app = Angel(reflector: MirrorsReflector());

  app.viewGenerator = (name, [data]) async =>
      'View generator invoked with name $name and data: $data';

  // Index route. Returns JSON.
  app.get('/', (req, res) => res.render('index', {'foo': 'bar'}));

  var http = AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening at $url');
}
