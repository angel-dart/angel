import 'package:angel_client/shared.dart';
import 'package:angel_client/browser.dart';
import 'package:test/test.dart';

main() async {
  Angel app = new Rest("http://localhost:3000");
  Service Todos = app.service("todos");

  print(await Todos.index());
}