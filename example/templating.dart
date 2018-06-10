import 'dart:io';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

main() async {
  var app = new Angel()
    ..lazyParseBodies = true
    ..logger = (new Logger('angel')..onRecord.listen(print))
    ..encoders.addAll({'gzip': gzip.encoder});
  var fs = const LocalFileSystem();
  var viewsDirPath = p.join(p.dirname(p.fromUri(Platform.script)), 'views');
  await app.configure(jael(fs.directory(viewsDirPath)));

  app.get('/', (ResponseContext res) => res.render('index'));

  var http = new AngelHttp(app);
  var server = await http.startServer('127.0.0.1', 3000);
  var url = 'http://${server.address.address}:${server.port}';
  print('Listening at $url');
}
