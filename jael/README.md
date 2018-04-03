# jael
[![Pub](https://img.shields.io/pub/v/jael.svg)](https://pub.dartlang.org/packages/jael)
[![build status](https://travis-ci.org/angel-dart/jael.svg)](https://travis-ci.org/angel-dart/jael)

A simple server-side HTML templating engine for Dart.

[See documentation.](https://github.com/angel-dart/jael/wiki)

# Installation
In your `pubspec.yaml`:

```yaml
dependencies:
  jael: ^1.0.0
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

    var buf = new CodeBuffer();
    var document = jael.parseDocument(template, sourceUrl: 'test.jl');
    var scope = new SymbolTable(values: {
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