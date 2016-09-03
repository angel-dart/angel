import 'package:angel_client/browser.dart';
import 'package:test/test.dart';

main() async {
  test("list todos", () async {
    Angel app = new Rest("http://localhost:3001");
    Service Todos = app.service("todos");

    print(await Todos.index());
  });
}
