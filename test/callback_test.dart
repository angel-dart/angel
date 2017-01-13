import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class User extends MemoryModel {
  String username, password;

  User({this.username, this.password});
}

main() {
  Angel app;
  AngelAuth auth;
  http.Client client;
  HttpServer server;
  String url;

  setUp(() async {
    app = new Angel();
    app.use('/users', new MemoryService<User>());

    await app
        .service('users')
        .create({'username': 'jdoe1', 'password': 'password'});

    await app.configure(auth = new AngelAuth());

    auth.serializer = (User user) async => user.id;
    auth.deserializer = app.service('users').read;

    auth.strategies.add(new LocalAuthStrategy((username, password) async {
      final List<User> users = await app.service('users').index();
      final found = users.firstWhere(
          (user) => user.username == username && user.password == password,
          orElse: () => null);

      return found != null ? found : false;
    }));

    app.post(
        '/login',
        auth.authenticate('local',
            new AngelAuthOptions(callback: (req, res, token) {
          res
            ..write('Hello!')
            ..end();
        })));

    client = new http.Client();
    server = await app.startServer();
    url = 'http://${server.address.address}:${server.port}';
  });

  tearDown(() async {
    client.close();
    await server.close(force: true);
    app = null;
    client = null;
    url = null;
  });

  test('login', () async {
    final response = await client.post('$url/login',
        body: {'username': 'jdoe1', 'password': 'password'});
    print('Response: ${response.body}');
    expect(response.body, equals('Hello!'));
  });
}
