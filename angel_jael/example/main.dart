import 'package:angel_framework/angel_framework.dart';
import 'package:angel_jael/angel_jael.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';

main() async {
  var app = new Angel()..lazyParseBodies = true;
  var fileSystem = const LocalFileSystem();

  await app.configure(
    jael(fileSystem.directory('views')),
  );

  app.get('/',
      (res) => res.render('index', {'title': 'Sample App', 'message': null}));

  app.post('/', (RequestContext req, res) async {
    var body = await req.lazyBody();
    var msg = body['message'] ?? '<unknown>';
    return await res
        .render('index', {'title': 'Form Submission', 'message': msg});
  });

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
