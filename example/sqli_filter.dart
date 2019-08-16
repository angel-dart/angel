import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_security/native.dart';
import 'package:logging/logging.dart';
import 'package:pretty_logging/pretty_logging.dart';

main() async {
  // Logging boilerplate.
  Logger.root.onRecord.listen(prettyLog);

  // Create an app, and HTTP driver.
  var app = Angel(logger: Logger('rate_limit')), http = AngelHttp(app);

  // Filter out SQL injections from the query. On every GET request,
  // print out the query parameters (as JSON).
  app
    ..fallback(sqliFilterQuery)
    ..get('/', (req, res) => req.queryParameters)
    ..fallback((req, res) => throw AngelHttpException.notFound());

  // Start the server.
  await http.startServer('127.0.0.1', 3000);
  print('SQLi filtering example listening at ${http.uri}');
}
