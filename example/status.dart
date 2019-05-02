import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';

main() async {
  var app = Angel();
  var http = AngelHttp(app);

  app.fallback((req, res) {
    res.statusCode = 304;
  });

  await http.startServer('127.0.0.1', 3000);
  print('Listening at ${http.uri}');
}
