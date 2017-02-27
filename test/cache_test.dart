import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:http/http.dart' show Client;
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  Directory testDir = new Directory('test');
  String url;
  Client client = new Client();

  setUp(() async {
    app = new Angel(debug: true);

    await app.configure(new CachingVirtualDirectory(
        source: testDir, maxAge: 350, onlyInProduction: false,
        //publicPath: '/virtual',
        indexFileNames: ['index.txt']));

    app.get('*', 'Fallback');

    app.dumpTree(showMatchers: true);

    await app.startServer(InternetAddress.LOOPBACK_IP_V4, 0);
    url = "http://${app.httpServer.address.host}:${app.httpServer.port}";
  });

  tearDown(() async {
    if (app.httpServer != null) await app.httpServer.close(force: true);
  });

  test('sets etag, cache-control, expires, last-modified', () async {
    var response = await client.get("$url");

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('Response headers: ${response.headers}');

    expect(response.statusCode, equals(200));
    expect(
        [
          HttpHeaders.ETAG,
          HttpHeaders.CACHE_CONTROL,
          HttpHeaders.EXPIRES,
          HttpHeaders.LAST_MODIFIED
        ],
        everyElement(predicate(
            response.headers.containsKey, 'contained in response headers')));
  });

  test('if-modified-since', () async {
    var response = await client.get("$url", headers: {
      HttpHeaders.IF_MODIFIED_SINCE:
          formatDateForHttp(new DateTime.now()..add(new Duration(days: 365)))
    });

    print('Response status: ${response.statusCode}');

    expect(response.statusCode, equals(304));
    expect(
        [
          HttpHeaders.CACHE_CONTROL,
          HttpHeaders.EXPIRES,
          HttpHeaders.LAST_MODIFIED
        ],
        everyElement(predicate(
            response.headers.containsKey, 'contained in response headers')));
  });
}
