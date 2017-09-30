import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';

main() async {
  var app = new Angel();
  var fileSystem = const LocalFileSystem();

  await app.configure(
    jael(fileSystem.directory('views')),
  );

  app.get('/', (res) => res.render('index', {'title': 'ESKETTIT'}));

  app.use(() => throw new AngelHttpException.notFound());

  app.logger = new Logger('angel')
    ..onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  var server = await app.startServer(null, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}
