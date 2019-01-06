# html
[![Pub](https://img.shields.io/pub/v/angel_html.svg)](https://pub.dartlang.org/packages/angel_html)
[![build status](https://travis-ci.org/angel-dart/html.svg)](https://travis-ci.org/angel-dart/html)

A plug-in that allows you to return html_builder AST's from request handlers, and have them sent as HTML automatically.

[`package:html_builder`](https://github.com/thosakwe/html_builder) is a simple virtual DOM library
(without diffing, you can find that
[here](https://github.com/thosakwe/html_builder_vdom)), with a handy Dart DSL that makes it easy to build HTML
AST's:

```dart
import 'package:html_builder/elements.dart';

Node myDom = html(lang: 'en', c: [
  head(c: [
    meta(name: 'viewport', content: 'width=device-width, initial-scale=1'),
    title(c: [
      text('html_builder example page')
    ]),
  ]),
  body(c: [
    h1(c: [
      text('Hello world!'),
    ]),
  ]),
]);
```

This plug-in means that you can now `return` these AST's, and Angel will automatically send them to
clients. Ultimately, the implication is that you can use `html_builder` as a substitute for a
templating system within Dart. With [hot reloading](https://github.com/angel-dart/hot), you won't
even need to reload your server (as it should be).

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  angel_html: ^1.0.0
```

# Usage
The `renderHtml` function does all the magic for you.

```dart
configureServer(Angel app) async {
  // Wire it up!
  app.fallback(renderHtml());
  
  // You can pass a custom StringRenderer if you need more control over the output.
  app.fallback(renderHtml(renderer: new StringRenderer(html5: false)));
  
  app.get('/greet/:name', (RequestContext req) {
    return html(lang: 'en', c: [
     head(c: [
       meta(name: 'viewport', content: 'width=device-width, initial-scale=1'),
       title(c: [
         text('Greetings!')
       ]),
     ]),
     body(c: [
       h1(c: [
         text('Hello, ${req.params['id']}!'),
       ]),
     ]),
   ]);
  });
}
```

By default, `renderHtml` will ignore the client's `Accept` header. However, if you pass
`enforceAcceptHeader` as `true`, then a `406 Not Acceptable` error will be thrown if the
client doesn't accept `*/*` or `text/html`.

```dart
configureServer(Angel app) async {
  // Wire it up!
  app.fallback(renderHtml(enforceAcceptHeader: true));
  
  // ...
}
```