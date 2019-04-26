import 'dart:io';
import 'package:angel_file_service/angel_file_service.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_typed_service/angel_typed_service.dart';
import 'package:file/local.dart';
import 'package:json_god/json_god.dart' as god;
import 'package:logging/logging.dart';

main() async {
  var app = Angel();
  var http = AngelHttp(app);
  var fs = LocalFileSystem();
  var exampleDir = fs.file(Platform.script).parent;
  var dataJson = exampleDir.childFile('data.json');
  var service = TypedService<String, Todo>(JsonFileService(dataJson));
  hierarchicalLoggingEnabled = true;
  app.use('/api/todos', service);

  app
    ..serializer = god.serialize
    ..logger = Logger.detached('typed_service')
    ..logger.onRecord.listen((rec) {
      print(rec);
      if (rec.error != null) print(rec.error);
      if (rec.stackTrace != null) print(rec.stackTrace);
    });

  await http.startServer('127.0.0.1', 3000);
  print('Listening at ${http.uri}');
}

class Todo extends Model {
  String text;
  bool completed;

  @override
  DateTime createdAt, updatedAt;

  Todo({String id, this.text, this.completed, this.createdAt, this.updatedAt})
      : super(id: id);
}
