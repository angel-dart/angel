import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/common.dart';
import 'package:dart2_constant/convert.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

class User extends Model {
  String username, password;

  User({this.username, this.password});
}

main() {
  Angel app;
  AngelHttp angelHttp;
  AngelAuth auth;
  http.Client client;
  HttpServer server;
  String url;

  setUp(() async {
    app = new Angel();
    angelHttp = new AngelHttp(app, useZone: false);
    app.use('/users', new TypedService<User>(new MapService()));

    User jdoe = await app
        .service('users')
        .create({'username': 'jdoe1', 'password': 'password'});

    auth = new AngelAuth<User>();
    auth.serializer = (u) => u.id;
    auth.deserializer = app.service('users').read;

    await app.configure(auth.configureServer);
    app.use(auth.decodeJwt);

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

    app.chain((RequestContext req) {
      req.properties['user'] =
          new User(username: req.params['name']?.toString());
      return true;
    }).post('/existing/:name', auth.authenticate('local'));

    client = new http.Client();
    server = await angelHttp.startServer();
    url = 'http://${server.address.address}:${server.port}';
  });

  tearDown(() async {
    client.close();
    await angelHttp.close();
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

  test('preserve existing user', () async {
    final response = await client.post('$url/existing/foo',
        body: {'username': 'jdoe1', 'password': 'password'},
        headers: {'accept': 'application/json'});
    print('Response: ${response.body}');
    expect(json.decode(response.body)['data']['username'], equals('foo'));
  });
}
