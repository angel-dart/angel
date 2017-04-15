# cors

![1.0.0+1](https://img.shields.io/badge/version-1.0.0+1-brightgreen.svg)
![build status](https://travis-ci.org/angel-dart/cors.svg)

Angel CORS middleware.
Port of [the original Express CORS middleware](https://github.com/expressjs/cors).

```dart
main() {
    var app = new Angel();
    app.before.add(cors());
}
```