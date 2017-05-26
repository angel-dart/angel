import 'package:angel_client/angel_client.dart' as c;
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_paginate/server.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

final List DATA = new List.filled(50, {'foo': 'bar'}, growable: true)
  ..addAll(new List.filled(25, {'bar': 'baz'}));

main() {
  group('no max', () {
    Angel app;
    TestClient client;
    c.Service dataService;

    setUp(() async {
      app = new Angel()
        ..use('/data', new AnonymousService(index: ([p]) async => DATA));
      await app.configure(logRequests());
      var service = app.service('data') as HookedService;
      service.afterIndexed.listen(paginate(itemsPerPage: 10));

      client = await connectTo(app);
      dataService = client.service('data');
    });

    tearDown(() => client.close());

    test('first page', () async {
      var response = await dataService
          .index()
          .then((m) => new PaginationResult.fromMap(m));
      print(response.toJson());

      expect(response.total, DATA.length);
      expect(response.itemsPerPage, 10);
      expect(response.startIndex, 0);
      expect(response.endIndex, 9);
      expect(response.previousPage, -1);
      expect(response.currentPage, 1);
      expect(response.nextPage, 2);
      expect(response.data, DATA.take(10).toList());
    });

    test('third page', () async {
      var response = await dataService.index({
        'query': {'page': 3}
      }).then((m) => new PaginationResult.fromMap(m));
      print(response.toJson());

      expect(response.total, DATA.length);
      expect(response.itemsPerPage, 10);
      expect(response.startIndex, 20);
      expect(response.endIndex, 29);
      expect(response.previousPage, 2);
      expect(response.currentPage, 3);
      expect(response.nextPage, 4);
      expect(response.data, DATA.skip(20).take(10).toList());
    });

    test('custom limit', () async {
      var response = await dataService.index({
        'query': {'page': 4, r'$limit': 5}
      }).then((m) => new PaginationResult.fromMap(m));
      print(response.toJson());

      expect(response.total, DATA.length);
      expect(response.itemsPerPage, 5);
      expect(response.startIndex, 15);
      expect(response.endIndex, 19);
      expect(response.previousPage, 3);
      expect(response.currentPage, 4);
      expect(response.nextPage, 5);
      expect(response.data, DATA.skip(15).take(5).toList());
    });
  });

  group('max 15', () {
    Angel app;
    TestClient client;
    c.Service dataService;

    setUp(() async {
      app = new Angel()
        ..use('/data', new AnonymousService(index: ([p]) async => DATA));
      await app.configure(logRequests());
      var service = app.service('data') as HookedService;
      service.afterIndexed.listen(
          paginate(itemsPerPage: 10, maxItemsPerPage: 15));

      client = await connectTo(app);
      dataService = client.service('data');
    });

    tearDown(() => client.close());

    test('exceed max', () async {
      var response = await dataService.index({
        'query': {'page': 4, r'$limit': 30}
      }).then((m) => new PaginationResult.fromMap(m));
      print(response.toJson());

      // Should default to 10 items per page :)
      expect(response.total, DATA.length);
      expect(response.itemsPerPage, 10);
      expect(response.startIndex, 30);
      expect(response.endIndex, 39);
      expect(response.previousPage, 3);
      expect(response.currentPage, 4);
      expect(response.nextPage, 5);
      expect(response.data, DATA.skip(30).take(10).toList());
    });
  });
}
