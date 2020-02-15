import 'package:angel_framework/angel_framework.dart' as srv;
import 'package:angel_poll/angel_poll.dart';
import 'package:angel_test/angel_test.dart';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  srv.Service store;
  TestClient client;
  PollingService pollingService;

  setUp(() async {
    var app = new srv.Angel();
    app.logger = new Logger.detached('angel_poll')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error != null) {
          print(rec.error);
          print(rec.stackTrace);
        }
      });

    store = app.use(
      '/api/todos',
      new srv.MapService(
        autoIdAndDateFields: false,
      ),
    );

    client = await connectTo(app);

    pollingService = new PollingService(
      client.service('api/todos'),
      const Duration(milliseconds: 100),
    );
  });

  tearDown(() => client.close());

  group('events', () {
    var created;
    StreamQueue onCreated, onModified, onRemoved;

    setUp(() async {
      onCreated = new StreamQueue(pollingService.onCreated);
      onModified = new StreamQueue(pollingService.onModified);
      onRemoved = new StreamQueue(pollingService.onRemoved);

      created = await store.create({
        'id': '0',
        'text': 'Clean your room',
        'completed': false,
      });
    });

    tearDown(() {
      onCreated.cancel();
      onModified.cancel();
      onRemoved.cancel();
    });

    test('fires indexed', () async {
      var indexed = await pollingService.index();
      print(indexed);
      expect(await pollingService.onIndexed.first, indexed);
    });

    test('fires created', () async {
      var result = await onCreated.next;
      print(result);
      expect(created, result);
    });

    test('fires modified', () async {
      await pollingService.index();
      await store.modify('0', {
        'text': 'go to school',
      });

      var result = await onModified.next;
      print(result);
      expect(result, new Map.from(created)..['text'] = 'go to school');
    });

    test('manual modify', () async {
      await pollingService.index();
      await pollingService.modify('0', {
        'text': 'eat',
      });

      var result = await onModified.next;
      print(result);
      expect(result, new Map.from(created)..['text'] = 'eat');
    });

    test('fires removed', () async {
      await pollingService.index();
      var removed = await store.remove('0');
      var result = await onRemoved.next;
      print(result);
      expect(result, removed);
    });
  });
}
