import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'package:angel_validate/angel_validate.dart';
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:pretty_logging/pretty_logging.dart';

main() async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(prettyLog);

  var app = Angel(logger: Logger('angel_validate'));
  var http = AngelHttp(app);

  var todoForm = Form(fields: [
    
  ]);

  app.get('/', (req, res) {
    res
      ..contentType = MediaType('text', 'html')
      ..write('''
    <!doctype html>
    <html>
      <body>
        <form method="POST">
          <label for="text">Text:</label>
          <input id="text" name="text">
          <br>
          <label for="is_complete">Complete?</label>
          <input id="is_complete" name="is_complete" type="checkbox">
          <br>
          <input type="submit" value="submit">
        </form>
      </body>
    </html>
    ''');
  });

  app.fallback((req, res) => throw AngelHttpException.notFound());

  app.errorHandler = (e, req, res) {
    res.writeln('Error ${e.statusCode}: ${e.message}');
    for (var error in e.errors) {
      res.writeln('* $error');
    }
  };

  await http.startServer('127.0.0.1', 3000);
}

class Todo {
  final String text;
  final bool isComplete;

  Todo(this.text, this.isComplete);

  static Todo fromMap(Map map) {
    return Todo(map['text'] as String, map['is_complete'] as bool);
  }
}
