# typed_service
Angel services that use reflection (via mirrors or codegen) to (de)serialize PODO's.
Useful for quick prototypes.

Typically, [`package:angel_serialize`](https://github.com/angel-dart/serialize)
is recommended.

## Brief Example
```dart
main() async {
  var app = Angel();
  var http = AngelHttp(app);
  var service = TypedService<String, Todo>(MapService());
  hierarchicalLoggingEnabled = true;
  app.use('/api/todos', service);

  app
    ..serializer = god.serialize
    ..logger = Logger.detached('typed_service')
    ..logger.onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  await http.startServer('127.0.0.1', 3000);
  print('Listening at ${http.uri}');
}
```