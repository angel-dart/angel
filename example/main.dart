import 'package:angel_eventsource/server.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_websocket/server.dart';
import 'package:eventsource/eventsource.dart';
import 'package:logging/logging.dart';
import 'pretty_logging.dart';

main() async {
  var app = new Angel();
  var ws = new AngelWebSocket(app);
  var events = new AngelEventSourcePublisher(ws);

  await app.configure(ws.configureServer);

  app.use('/api/todos', new MapService());
  app.all('/ws', ws.handleRequest);
  app.get('/events', events.handleRequest);

  app.logger = new Logger('angel_eventsource')..onRecord.listen(prettyLog);

  var http = new AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  var url = Uri.parse('http://${server.address.address}:${server.port}');
  print('Listening at $url');

  /*
  var sock = await Socket.connect(server.address, server.port);
  sock
    ..writeln('GET /sse HTTP/1.1')
    ..writeln('Accept: text/event-stream')
    ..writeln('Host: 127.0.0.1')
    ..writeln()
    ..flush();
  sock.transform(UTF8.decoder).transform(const LineSplitter()).listen(print);
  */

  /*
  var client = new HttpClient();
  var rq = await client.openUrl('GET', url);
  var rs = await rq.close();
  rs.transform(UTF8.decoder).transform(const LineSplitter()).listen(print);
  */

  var eventSource = await EventSource.connect(url);

  await for (var event in eventSource) {
    print(event.data);
  }
}
