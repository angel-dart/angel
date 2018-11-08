import 'package:angel_framework/angel_framework.dart';
import 'package:angel_seo/angel_seo.dart';
import 'package:angel_static/angel_static.dart';
import 'package:angel_test/angel_test.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('inlineAssets', () {
    group('buffer', inlineAssetsTests((app, dir) {
      app.get('/', (req, res) async {
        var indexHtml = dir.childFile('index.html');
        var contents = await indexHtml.readAsBytes();
        res
          ..useBuffer()
          ..contentType = new MediaType.parse('text/html; charset=utf-8')
          ..buffer.add(contents);
      });

      app.responseFinalizers.add(inlineAssets(dir));
    }));

    group('virtual_directory', inlineAssetsTests((app, dir) {
      var vDir = inlineAssetsFromVirtualDirectory(
          new VirtualDirectory(app, dir.fileSystem, source: dir));
      app.fallback(vDir.handleRequest);
    }));
  });
}

/// Typedef for backwards-compatibility with Dart 1.
typedef void InlineAssetTest(Angel app, Directory dir);

void Function() inlineAssetsTests(InlineAssetTest f) {
  return () {
    TestClient client;

    setUp(() async {
      var app = new Angel();
      var fs = new MemoryFileSystem();
      var dir = fs.currentDirectory;
      f(app, dir);
      client = await connectTo(app);

      for (var path in contents.keys) {
        var file = fs.file(path);
        await file.writeAsString(contents[path].trim());
      }

      app.logger = new Logger('angel_seo')
        ..onRecord.listen((rec) {
          print(rec);
          if (rec.error != null) print(rec.error);
          if (rec.stackTrace != null) print(rec.stackTrace);
        });
    });

    tearDown(() => client.close());

    group('sends html', () {
      html.Document doc;

      setUp(() async {
        var res = await client.get('/', headers: {'accept': 'text/html'});
        print(res.body);
        doc = html.parse(res.body);
      });

      group('stylesheets', () {
        test('replaces <link> with <style>', () {
          expect(doc.querySelectorAll('link'), hasLength(1));
        });

        test('populates a <style>', () {
          var style = doc.querySelector('style');
          expect(style?.innerHtml?.trim(), contents['site.css']);
        });

        test('heeds data-no-inline', () {
          var link = doc.querySelector('link');
          expect(link.attributes, containsPair('rel', 'stylesheet'));
          expect(link.attributes, containsPair('href', 'not-inlined.css'));
          expect(link.attributes.keys, isNot(contains('data-no-inline')));
        });

        test('preserves other attributes', () {
          var link = doc.querySelector('link');
          expect(link.attributes, containsPair('data-foo', 'bar'));
        });
      });

      group('scripts', () {
        test('does not replace <script> with anything', () {
          expect(doc.querySelectorAll('script'), hasLength(2));
        });

        test('populates innerHtml', () {
          var script0 = doc.querySelectorAll('script')[0];
          expect(script0.innerHtml.trim(), contents['site.js']);
        });

        test('heeds data-no-inline', () {
          var script1 = doc.querySelectorAll('script')[1];
          expect(script1.attributes, containsPair('src', 'not-inlined.js'));
          expect(script1.attributes.keys, isNot(contains('data-no-inline')));
        });

        test('preserves other attributes', () {
          var script0 = doc.querySelectorAll('script')[0];
          var script1 = doc.querySelectorAll('script')[1];
          expect(script0.attributes, containsPair('data-foo', 'bar'));
          expect(script1.attributes, containsPair('type', 'text/javascript'));
        });
      });
    });
  };
}

var contents = <String, String>{
  'index.html': '''<!doctype html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <link rel="stylesheet" href="site.css">
    <link data-foo="bar" rel="stylesheet" href="not-inlined.css" data-no-inline>
    <script data-foo="bar" src="site.js"></script>
    <script type="text/javascript" src="not-inlined.js" data-no-inline></script>
    <title>Angel SEO</title>
</head>
<body>
<h1>Angel SEO</h1>
<p>Embrace the power of inlined styles, etc.</p>
</body>
</html>''',
  'not-inlined.css': '''p {
    font-style: italic;
}''',
  'not-inlined.js': '''window.addEventListener('load', function() {
  console.log('THIS message was not from an inlined file.');
});''',
  'site.css': '''h1 {
    color: pink;
}''',
  'site.js': '''window.addEventListener('load', function() {
  console.log('Hello, inline world!');
});'''
};
