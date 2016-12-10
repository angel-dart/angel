import 'package:angel_framework/angel_framework.dart' as server;
import 'package:angel_client/angel_client.dart' as client;
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

main() {
  server.Angel app;
  client.Angel clientApp;

  setUp(() async {
    app.get('/hello', 'Hello');

    clientApp = await connectTo(app);
  });

  tearDown(clientApp.close);
}