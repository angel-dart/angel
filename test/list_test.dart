import 'package:async/async.dart';
import 'dart:io';
import 'package:angel_client/io.dart' as c;
import 'package:angel_framework/angel_framework.dart' as s;
import 'package:angel_framework/http.dart' as s;
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

main() {
  HttpServer server;
  c.Angel app;
  c.ServiceList list;
  StreamQueue queue;

  setUp(() async {
    var serverApp = new s.Angel();
    var http = new s.AngelHttp(serverApp);
    serverApp.use('/api/todos', new s.MapService(autoIdAndDateFields: false));

    server = await http.startServer();
    var uri = 'http://${server.address.address}:${server.port}';
    app = new c.Rest(uri);
    list = new c.ServiceList(app.service('api/todos'));
    queue = new StreamQueue(list.onChange);
  });

  tearDown(() async {
    await server.close(force: true);
    unawaited(list.close());
    unawaited(list.service.close());
    unawaited(app.close());
  });

  test('listens on create', () async {
    unawaited(list.service.create({'foo': 'bar'}));
    await list.onChange.first;
    expect(list, [
      {'foo': 'bar'}
    ]);
  });

  test('listens on modify', () async {
    unawaited(list.service.create({'id': 1, 'foo': 'bar'}));
    await queue.next;

    await list.service.update(1, {'id': 1, 'bar': 'baz'});
    await queue.next;
    expect(list, [
      {'id': 1, 'bar': 'baz'}
    ]);
  });

  test('listens on remove', () async {
    unawaited(list.service.create({'id': '1', 'foo': 'bar'}));
    await queue.next;

    await list.service.remove('1');
    await queue.next;
    expect(list, isEmpty);
  });
}
