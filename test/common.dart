import 'package:angel_framework/angel_framework.dart';

Angel testApp() {
  final app = new Angel();

  app.get('/hello', 'world');
  app.get('/foo/bar', 'baz');

  return app;
}