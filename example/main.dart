import 'dart:async';
import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_markdown/angel_markdown.dart';
import 'package:file/local.dart';

main() async {
  var app = await createServer();
  var http = AngelHttp(app);
  var server = await http.startServer(InternetAddress.loopbackIPv4, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}

Future<Angel> createServer() async {
  // Create a new server, and install the Markdown renderer.
  var app = new Angel();
  var fs = LocalFileSystem();
  await app
      .configure(markdown(fs.directory('views'), template: (content, locals) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <title>${locals['title'] ?? 'Example Site'} - Example Site</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/semantic-ui/2.2.13/semantic.min.css">
  </head>
  <body>
    <div class="ui top fixed menu">
      <a class="header item" href="/">
        <i class="home icon"></i>
        Home
      </a>
    </div>
    <div class="ui container" style="margin-top: 5em;">
      $content
    </div>
  </body>
</html>
    ''';
  }));

  // Compile a landing page
  app.get('/', (req, res) => res.render('hello', {'title': 'Welcome'}));

  return app;
}
