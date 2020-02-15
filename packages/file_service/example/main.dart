import 'package:angel_file_service/angel_file_service.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:file/local.dart';

configureServer(Angel app) async {
  // Just like a normal service
  app.use(
    '/api/todos',
    new JsonFileService(const LocalFileSystem().file('todos_db.json')),
  );
}
