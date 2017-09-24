import 'package:angel_framework/angel_framework.dart';
import 'package:logging/logging.dart';

Angel testApp() {
  final app = new Angel()..lazyParseBodies = true;

  app.get('/hello', 'world');
  app.get('/foo/bar', 'baz');
  app.post('/body', (RequestContext req, res) async {
    var body = await req.lazyBody();
    print('Body: $body');
    return body;
  });

  app.logger = new Logger('testApp');

  return app..dumpTree();
}
