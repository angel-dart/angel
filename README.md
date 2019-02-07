# cors
[![Pub](https://img.shields.io/pub/v/angel_cors.svg)](https://pub.dartlang.org/packages/angel_cors)
[![build status](https://travis-ci.org/angel-dart/cors.svg)](https://travis-ci.org/angel-dart/cors)

Angel CORS middleware.
Port of [the original Express CORS middleware](https://github.com/expressjs/cors).

```dart
main() {
    var app = new Angel();
    app.fallback(cors());
}
```