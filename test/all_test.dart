import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:http/http.dart' show Client;
import 'package:test/test.dart';

main() {
  Angel app;
  Directory testDir = new Directory('test');
  String url;
  Client client = new Client();

  setUp(() async {
    app = new Angel(debug: true);

    await app.configure(new VirtualDirectory(
        debug: true,
        source: testDir,
        publicPath: '/virtual',
        indexFileNames: ['index.txt']));

    await app.configure(new VirtualDirectory(
        debug: true,
        source: testDir,
        indexFileNames: ['index.php', 'index.txt']));

    app.get('*', 'Fallback');

    app.dumpTree(showMatchers: true);

    await app.startServer(InternetAddress.LOOPBACK_IP_V4, 0);
    url = "http://${app.httpServer.address.host}:${app.httpServer.port}";
  });

  tearDown(() async {
    if (app.httpServer != null) await app.httpServer.close(force: true);
  });

  test('can serve files, with correct Content-Type', () async {
    var response = await client.get("$url/sample.txt");
    expect(response.body, equals("Hello world"));
    expect(response.headers[HttpHeaders.CONTENT_TYPE], equals("text/plain"));
  });

  test('non-existent files are skipped', () async {
    var response = await client.get("$url/nonexist.ent");
    expect(response.body, equals('"Fallback"'));
  });

  test('can match index files', () async {
    var response = await client.get(url);
    expect(response.body, equals("index!"));
  });

  test('virtualRoots can match index', () async {
    var response = await client.get("$url/virtual");
    expect(response.body, equals("index!"));
  });
}
