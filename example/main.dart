import "package:angel_framework/angel_framework.dart";
import "package:angel_websocket/server.dart";

main() async {
  var app = new Angel();
  var http = new AngelHttp(app);
  var ws = new AngelWebSocket(app);

  // This is a plug-in. It hooks all your services,
  // to automatically broadcast events.
  await app.configure(ws.configureServer);

  // Listen for requests at `/ws`.
  app.all('/ws', ws.handleRequest);

  var server = await http.startServer('127.0.0.1', 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
