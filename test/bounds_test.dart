import 'package:angel_client/angel_client.dart' as c;
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_paginate/server.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

final List<Map<String, String>> DATA = [
  {'billie': 'jean'},
  {'off': 'the_wall'},
  {'michael': 'jackson'}
];

main() {
  TestClient client;
  c.Service songService;

  setUp(() async {
    var app = new Angel()
      ..use('/api/songs', new AnonymousService(index: ([p]) async => DATA));
    var service = app.service('api/songs') as HookedService;
    service.afterIndexed.listen(paginate(itemsPerPage: 2));
    await app.configure(logRequests());
    client = await connectTo(app);
    songService = client.service('api/songs');
  });

  tearDown(() => client.close());

  test('limit exceeds size of collection', () async {
    var response = await songService.index({
      'query': {
        r'$limit': DATA.length + 1
      }
    });

    var page = new PaginationResult<Map<String, String>>.fromMap(response);
    print('page: ${page.toJson()}');

    expect(page.total, DATA.length);
    expect(page.itemsPerPage, DATA.length);
    expect(page.previousPage, -1);
    expect(page.currentPage, 1);
    expect(page.nextPage, -1);
    expect(page.startIndex, 0);
    expect(page.endIndex, DATA.length - 1);
    expect(page.data, DATA);
  });
}
