# jael
[![Pub](https://img.shields.io/pub/v/jael.svg)](https://pub.dartlang.org/packages/jael)
[![build status](https://travis-ci.org/angel-dart/jael.svg)](https://travis-ci.org/angel-dart/jael)

A simple server-side HTML templating engine for Dart.

[See documentation.](https://docs.angel-dart.dev/packages/front-end/jael)

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  jael: ^2.0.0
```

# API
The core `jael` package exports classes for parsing Jael templates,
an AST library, and a `Renderer` class that generates HTML on-the-fly.

```dart
import 'package:code_buffer/code_buffer.dart';
import 'package:jael/jael.dart' as jael;
import 'package:symbol_table/symbol_table.dart';

void myFunction() {
    const template = '''
<html>
  <body>
    <h1>Hello</h1>
    <img src=profile['avatar']>
  </body>
</html>
''';

    var buf = CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jael', asDSX: false);
    var scope = SymbolTable(values: {
      'profile': {
        'avatar': 'thosakwe.png',
      }
    });

    const jael.Renderer().render(document, buf, scope);
    print(buf);
}
```

Pre-processing (i.e. handling of blocks and includes) is handled
by `package:jael_preprocessor.`.
