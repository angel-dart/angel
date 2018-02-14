import 'dart:convert';
import 'dart:io';
import 'package:angel_eventsource/server.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:eventsource/eventsource.dart';
import 'package:eventsource/publisher.dart';
import 'package:logging/logging.dart';
import 'pretty_logging.dart';

main() async {
  var app = new Angel();

  app.use('/api/todos', new MapService());

  var publisher = new AngelEventSourcePublisher(new EventSourcePublisher());
  await app.configure(publisher.configureServer);

  app.get('/sse', publisher.handleRequest);

  app.logger = new Logger('angel_eventsource')..onRecord.listen(prettyLog);

  var server = await app.startServer('127.0.0.1', 3000);
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
