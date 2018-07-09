# seo
Helpers for building SEO-friendly Web pages in Angel. The goal of
`package:angel_seo` is to speed up perceived client page loads, prevent
the infamous
[flash of unstyled content](https://en.wikipedia.org/wiki/Flash_of_unstyled_content),
and other SEO optimizations that can easily become tedious to perform by hand.

## `inlineAssets`
This function is a simple one; it wraps a `VirtualDirectory` to patch the way it sends
`.html` files.

In any `.html` file sent down, `link` and `script` elements that point to internal resources
will have the contents of said file read, and inlined into the HTML page itself.

In this case, "internal resources" refers to a URI *without* a scheme, i.e. `/site.css` or
`foo/bar/baz.js`.

```dart
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_seo/angel_seo.dart';
import 'package:angel_static/angel_static.dart';
import 'package:file/local.dart';

main() async {
  var app = new Angel()..lazyParseBodies = true;
  var fs = const LocalFileSystem();
  var http = new AngelHttp(app);

  var vDir = inlineAssets(
    new VirtualDirectory(
      app,
      fs,
      source: fs.directory('web'),
    ),
  );

  app.use(vDir.handleRequest);

  app.use(() => throw new AngelHttpException.notFound());

  var server = await http.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}

```