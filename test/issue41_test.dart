import 'dart:async';
import 'dart:io';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

final Directory swaggerUiDistDir =
    new Directory('test/node_modules/swagger-ui-dist');

main() async {
  TestClient client;
  String swaggerUiCssContents, swaggerTestJsContents;

  setUp(() async {
    // Load file contents
    swaggerUiCssContents =
        await new File.fromUri(swaggerUiDistDir.uri.resolve('swagger-ui.css'))
            .readAsString();
    swaggerTestJsContents =
        await new File.fromUri(swaggerUiDistDir.uri.resolve('test.js'))
            .readAsString();

    // Initialize app
    var app = new Angel();
    await Future.forEach([
      new VirtualDirectory(source: swaggerUiDistDir, publicPath: 'swagger/'),
      logRequests()
    ], app.configure);

    app.dumpTree();
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('prefix is not replaced in file paths', () async {
    var response = await client.get('/swagger/swagger-ui.css');
    print('Response: ${response.body}');
    expect(response, hasBody(swaggerUiCssContents));
  });

  test('get a file without prefix in name', () async {
    var response = await client.get('/swagger/test.js');
    print('Response: ${response.body}');
    expect(response, hasBody(swaggerTestJsContents));
  });

  test('trailing slash at root', () async {
    var response = await client.get('/swagger');
    var body1 = response.body;
    print('Response #1: $body1');

    response = await client.get('/swagger/');
    var body2 = response.body;
    print('Response #2: $body2');

    expect(body1, body2);
  });
}
