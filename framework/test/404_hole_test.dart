import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:charcode/ascii.dart';
import 'package:http/io_client.dart' as http;
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'pretty_log.dart';

void main() {
  http.IOClient client;
  AngelHttp driver;
  Logger logger;

  setUp(() async {
    client = http.IOClient();
    hierarchicalLoggingEnabled = true;

    logger = Logger.detached('404_hole')
      ..level = Level.ALL
      ..onRecord.listen(prettyLog);

    var app = Angel(logger: logger);

    app.fallback(hello);
    app.fallback(throw404);

    // The error handler in the boilerplate.
    var oldErrorHandler = app.errorHandler;
    app.errorHandler = (e, req, res) async {
      if (req.accepts('text/html', strict: true)) {
        if (e.statusCode == 404 && req.accepts('text/html', strict: true)) {
          await res
              .render('error', {'message': 'No file exists at ${req.uri}.'});
        } else {
          await res.render('error', {'message': e.message});
        }
      } else {
        return await oldErrorHandler(e, req, res);
      }
    };

    driver = AngelHttp(app);
    await driver.startServer();
  });

  tearDown(() {
    logger.clearListeners();
    client.close();
    scheduleMicrotask(driver.close);
  });

  test('does not continue processing after streaming', () async {
    var url = driver.uri.replace(path: '/hey');
    for (int i = 0; i < 100; i++) {
      var r = await client.get(url);
      print('#$i: ${r.statusCode}: ${r.body}');
      expect(r.statusCode, 200);
      expect(r.body, 'Hello!');
    }
  });
}

/// Simulate angel_static
Future<void> hello(RequestContext req, ResponseContext res) {
  if (req.path == 'hey') {
    var bytes = [$H, $e, $l, $l, $o, $exclamation];
    var s = Stream<List<int>>.fromIterable([bytes]);
    return s.pipe(res);
  } else {
    return Future.value(true);
  }
}

/// 404
void throw404(RequestContext req, ResponseContext res) {
  Zone.current
      .handleUncaughtError('This 404 should not occur.', StackTrace.current);
  throw AngelHttpException.notFound();
}
