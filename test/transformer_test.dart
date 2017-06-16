import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() {
  TestClient client;

  setUp(() async {
    var app = new Angel();
    var vDir = new CachingVirtualDirectory(
        source: new Directory('test'),
        transformers: [new ExtensionTransformer()]);
    await app.configure(vDir);
    await vDir.transformersLoaded.then((map) {
      print('Loaded transformer map: $map');
    });
    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('foo', () async {
    var response = await client.get('/index.ext');
    print('Response: ${response.body}');
    expect(response, hasBody('.txt'));
  });
}

class ExtensionTransformer implements FileTransformer {
  @override
  FileInfo declareOutput(FileInfo file) {
    return file.extension == '.ext' ? null : file.changeExtension('.ext');
  }

  @override
  FutureOr<FileInfo> transform(FileInfo file) =>
      file.changeText(file.extension).changeExtension('.ext');
}
