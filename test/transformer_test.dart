import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_test/angel_test.dart';
import 'package:mustache4dart/mustache4dart.dart' as ms;
import 'package:test/test.dart';

main() {
  TestClient client, client2;

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

    var app2 = new Angel();
    var vDir2 = new CachingVirtualDirectory(
        source: new Directory('test'),
        transformers: [
          new MustacheTransformer({'foo': 'bar'})
        ]);
    await app2.configure(vDir2);
    await vDir2.transformersLoaded.then((map) {
      print('Loaded transformer map2: $map');
    });
    client2 = await connectTo(app2);
  });

  tearDown(() => client.close().then((_) => client2.close()));

  test('foo', () async {
    var response = await client.get('/index.ext');
    print('Response: ${response.body}');
    expect(response, hasBody('.txt'));
  });

  test('request twice in a row', () async {
    var response = await client2.get('/foo.html');
    print('Response: ${response.body}');
    print('Response headers: ${response.headers}');
    expect(response, hasBody('<h1>bar</h1>'));

    var response2 = await client2.get('/foo.html');
    expect(response2, hasHeader(HttpHeaders.CONTENT_TYPE, ContentType.HTML.mimeType));
    print('Response2: ${response2.body}');
    expect(response2, hasBody('<h1>bar</h1>'));
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

class MustacheTransformer implements FileTransformer {
  final Map<String, dynamic> locals;

  MustacheTransformer(this.locals);

  @override
  FileInfo declareOutput(FileInfo file) =>
      file.extension == '.mustache' ? file.changeExtension('.html') : null;

  @override
  FutureOr<FileInfo> transform(FileInfo file) async {
    var template = await file.content.transform(UTF8.decoder).join();
    var compiled = ms.render(template, locals ?? {});
    return file.changeExtension('.html').changeText(compiled);
  }
}
