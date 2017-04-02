import 'package:angel_framework/angel_framework.dart';

Angel testApp() {
  final app = new Angel();

  app.get('/hello', 'world');
  app.get('/foo/bar', 'baz');
  app.post('/body', (req, res) => req.lazyBody());

  app.fatalErrorStream.listen((e) {
    print('FATAL IN TEST APP: ${e.error}');
    print(e.stack);
  });

  return app..dumpTree();
}
