import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_test/angel_test.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  MemoryFileSystem fileSystem;
  TestClient client;

  setUp(() async {
    fileSystem = MemoryFileSystem();

    var webDir = fileSystem.directory('web');
    await webDir.create(recursive: true);

    var indexFile = webDir.childFile('index.html');
    await indexFile.writeAsString('index');

    app = Angel();

    var vDir = VirtualDirectory(
      app,
      fileSystem,
      source: webDir,
    );

    app
      ..fallback(vDir.handleRequest)
      ..fallback(vDir.pushState('index.html'))
      ..fallback((req, res) => 'Fallback');

    app.logger = Logger('push_state')
      ..onRecord.listen(
        (rec) {
          print(rec);
          if (rec.error != null) print(rec.error);
          if (rec.stackTrace != null) print(rec.stackTrace);
        },
      );

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('serves as fallback', () async {
    var response = await client.get('/nope');
    expect(response.body, 'index');
  });
}
