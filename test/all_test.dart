import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_shelf/angel_shelf.dart';
import 'package:angel_test/angel_test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:test/test.dart';

main() async {
  Angel app;
  TestClient client;

  setUp(() async {
    var handler = new shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_echoRequest);

    app = new Angel();
    app.get('/angel', 'Angel');
    app.after.add(embedShelf(handler));

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('expose angel side', () async {
    var response = await client.get('/angel');
    expect(JSON.decode(response.body), equals('Angel'));
  });

  test('expose shelf side', () async {
    var response = await client.get('/foo');
    expect(response, hasStatus(200));
    expect(response.body, equals('Request for "foo"'));
  });
}

shelf.Response _echoRequest(shelf.Request request) {
  return new shelf.Response.ok('Request for "${request.url}"');
}
