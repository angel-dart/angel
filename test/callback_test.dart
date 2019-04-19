import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:angel_framework/http.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:io/ansi.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

class User extends Model {
  String username, password;

  User({this.username, this.password});

  static User parse(Map map) {
    return User(
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String()
    };
  }
}

main() {
  Angel app;
  AngelHttp angelHttp;
  AngelAuth<User> auth;
  http.Client client;
  HttpServer server;
  String url;

  setUp(() async {
    hierarchicalLoggingEnabled = true;
    app = Angel();
    angelHttp = AngelHttp(app);
    app.use('/users', MapService());

    var oldErrorHandler = app.errorHandler;
    app.errorHandler = (e, req, res) {
      app.logger.severe(e.message, e, e.stackTrace ?? StackTrace.current);
      return oldErrorHandler(e, req, res);
    };

    app.logger = Logger('angel_auth')
      ..level = Level.FINEST
      ..onRecord.listen((rec) {
        print(rec);

        if (rec.error != null) {
          print(yellow.wrap(rec.error.toString()));
        }

        if (rec.stackTrace != null) {
          print(yellow.wrap(rec.stackTrace.toString()));
        }
      });

    await app
        .findService('users')
        .create({'username': 'jdoe1', 'password': 'password'});

    auth = AngelAuth<User>();
    auth.serializer = (u) => u.id;
    auth.deserializer =
        (id) async => await app.findService('users').read(id) as User;

    await app.configure(auth.configureServer);

    auth.strategies['local'] = LocalAuthStrategy((username, password) async {
      var users = await app
          .findService('users')
          .index()
          .then((it) => it.map<User>((m) => User.parse(m as Map)).toList());
      return users.firstWhere(
          (user) => user.username == username && user.password == password,
          orElse: () => null);
    });

    app.post(
        '/login',
        auth.authenticate('local',
            AngelAuthOptions(callback: (req, res, token) {
          res
            ..write('Hello!')
            ..close();
        })));

    app.chain([
      (req, res) {
        if (!req.container.has<User>()) {
          req.container.registerSingleton<User>(
              User(username: req.params['name']?.toString()));
        }
        return true;
      }
    ]).post(
      '/existing/:name',
      auth.authenticate('local'),
    );

    client = http.Client();
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
  },
      skip: Platform.version.contains('2.0.0-dev')
          ? 'Blocked on https://github.com/dart-lang/sdk/issues/33594'
          : null);

  test('preserve existing user', () async {
    final response = await client.post('$url/existing/foo',
        body: {'username': 'jdoe1', 'password': 'password'},
        headers: {'accept': 'application/json'});
    print('Response: ${response.body}');
    expect(json.decode(response.body)['data']['username'], equals('foo'));
  });
}
