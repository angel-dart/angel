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
  var todos = <Todo>[];

  /// We can combine fields into a form; this is most
  /// useful when we immediately deserialize the form into
  /// something else.
  var todoForm = Form(fields: [
    TextField('text'),
    BoolField('is_complete'),
  ]);

  /// We can directly use a `Form` to deserialize a
  /// request body into a `Map<String, dynamic>`.
  ///
  /// By calling `deserialize` or `decode`, we can populate
  /// concrete Dart objects.
  app.post('/', (req, res) async {
    var todo = await todoForm.deserialize(req, Todo.fromMap);
    todos.add(todo);
    await res.redirect('/');
  });

  /// You can also use `Field`s to read directly from the
  /// request, without `as` casts.
  ///
  /// In this handler, we read the value of `name` from the query.
  app.get('/hello', (req, res) async {
    var nameField = TextField('name');
    var name = await nameField.getValue(req, query: true);
    return 'Hello, $name!';
  });

  /// Simple page displaying a form and some state.
  app.get('/', (req, res) {
    res
      ..contentType = MediaType('text', 'html')
      ..write('''
    <!doctype html>
    <html>
      <body>
        <h1>angel_validate</h1>
        <ul>
          ${todos.map((t) {
        return '<li>${t.text} (isComplete=${t.isComplete})</li>';
      }).join()}
        </ul>
        <form method="POST">
          <label for="text">Text:</label>
          <input id="text" name="text">
          <br>
          <label for="is_complete">Complete?</label>
          <input id="is_complete" name="is_complete" type="checkbox">
          <br>
          <button type="submit">Add Todo</button>
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
  print('Listening at ${http.uri}');
}

class Todo {
  final String text;
  final bool isComplete;

  Todo(this.text, this.isComplete);

  static Todo fromMap(Map map) {
    return Todo(map['text'] as String, map['is_complete'] as bool);
  }
}
