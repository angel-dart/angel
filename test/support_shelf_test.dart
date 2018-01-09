import 'package:angel_framework/angel_framework.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:angel_test/angel_test.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';
import 'pretty_logging.dart';

main() {
  TestClient client;

  setUp(() async {
    var app = new Angel()..lazyParseBodies = true;
    await app.configure(supportShelf());

    app.get('/inject', (shelf.Request request) {
      print('URL of injected request: ${request.url.path}');
      return {'inject': request.url.path == 'inject'};
    });

    app.get('/hello', (shelf.Request request) {
      return new shelf.Response.ok('world');
    });

    app.logger = new Logger.detached('angel')..onRecord.listen(prettyLog);
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('injected into request', () async {
    var response = await client.get('/inject', headers: {'accept': 'application/json'});
    print('Response: ${response.body}');
    expect(response, isJson({'inject': true}));
  });

  test('can return shelf response', () {
    return Chain.capture(() async {
      var response = await client.get('/hello', headers: {'accept': 'application/json'});
      print('Response: ${response.body}');
      expect(response, hasBody('world'));
    }, onError: (e, chain) {
      print(e);
      print(chain.terse);
      expect(0, 1);
    });
  });
}
