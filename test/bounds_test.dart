import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_paginate/angel_paginate.dart';
import 'package:angel_test/angel_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

final List<Map<String, String>> mjAlbums = [
  {'billie': 'jean'},
  {'off': 'the_wall'},
  {'michael': 'jackson'}
];

main() {
  TestClient client;

  setUp(() async {
    var app = new Angel();

    app.get('/api/songs', (req, res) {
      var p = Paginator(mjAlbums, itemsPerPage: mjAlbums.length);
      p.goToPage(int.parse(req.queryParameters['page'] ?? '1'));
      return p.current;
    });

    client = await connectTo(app);

    app.logger = Logger('angel_paginate')
      ..onRecord.listen((rec) {
        print(rec);
        if (rec.error != null) print(rec.error);
        if (rec.stackTrace != null) print(rec.stackTrace);
      });
  });

  tearDown(() => client.close());

  test('limit exceeds size of collection', () async {
    var response = await client.get(Uri(
        path: '/api/songs',
        queryParameters: {r'$limit': (mjAlbums.length + 1).toString()}));

    var page = new PaginationResult<Map<String, dynamic>>.fromMap(
        json.decode(response.body));

    print('page: ${page.toJson()}');

    expect(page.total, mjAlbums.length);
    expect(page.itemsPerPage, mjAlbums.length);
    expect(page.previousPage, -1);
    expect(page.currentPage, 1);
    expect(page.nextPage, -1);
    expect(page.startIndex, 0);
    expect(page.endIndex, mjAlbums.length - 1);
    expect(page.data, mjAlbums);
  });
}
