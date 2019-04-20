import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_test/angel_test.dart';
import 'package:test/test.dart';

class User {
  final List<String> roles;

  User(this.roles);
}

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = Angel();

    app.fallback((req, res) async {
      // In real life, you'd use auth to check user roles,
      // but in this case, let's just set the user manually
      var xRoles = req.headers['X-Roles'];

      if (xRoles?.isNotEmpty == true) {
        req.container.registerSingleton(User(xRoles));
      }

      return true;
    });

    app.chain([PermissionBuilder.wildcard().toPermission().toMiddleware()]).get(
        '/', (req, res) => 'Hello, world!');
    app.chain([Permission('foo').toMiddleware()]).get(
        '/one', (req, res) => 'Hello, world!');
    app.chain([Permission('two:foo').toMiddleware()]).get(
        '/two', (req, res) => 'Hello, world!');
    app.chain([Permission('two:*').toMiddleware()]).get(
        '/two-star', (req, res) => 'Hello, world!');
    app.chain([Permission('three:foo:bar').toMiddleware()]).get(
        '/three', (req, res) => 'Hello, world!');
    app.chain([Permission('three:*:bar').toMiddleware()]).get(
        '/three-star', (req, res) => 'Hello, world!');

    app.chain([
      PermissionBuilder('super')
          .add('specific')
          .add('permission')
          .allowAll()
          .or(PermissionBuilder('admin'))
          .toPermission()
          .toMiddleware()
    ]).get('/or', (req, res) => 'Hello, world!');

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  test('open permission', () async {
    var response = await client.get('/', headers: {'X-Roles': 'foo'});
    print('Response: ${response.body}');
    expect(response, hasStatus(200));
    expect(response, isJson('Hello, world!'));
  });

  group('restrict', () {
    test('one', () async {
      var response = await client.get('/one', headers: {'X-Roles': 'foo'});
      print('Response: ${response.body}');
      expect(response, hasStatus(200));
      expect(response, isJson('Hello, world!'));

      response = await client.get('/one', headers: {'X-Roles': 'bar'});
      print('Response: ${response.body}');
      expect(response, hasStatus(403));
    });

    test('two', () async {
      var response = await client.get('/two', headers: {'X-Roles': 'two:foo'});
      print('Response: ${response.body}');
      expect(response, hasStatus(200));
      expect(response, isJson('Hello, world!'));

      response = await client.get('/two', headers: {'X-Roles': 'two:bar'});
      print('Response: ${response.body}');
      expect(response, hasStatus(403));
    });

    test('two with star', () async {
      var response =
          await client.get('/two-star', headers: {'X-Roles': 'two:foo'});
      print('Response: ${response.body}');
      expect(response, hasStatus(200));
      expect(response, isJson('Hello, world!'));

      response =
          await client.get('/two-star', headers: {'X-Roles': 'three:foo'});
      print('Response: ${response.body}');
      expect(response, hasStatus(403));
    });

    test('three', () async {
      var response =
          await client.get('/three', headers: {'X-Roles': 'three:foo:bar'});
      print('Response: ${response.body}');
      expect(response, hasStatus(200));
      expect(response, isJson('Hello, world!'));

      response =
          await client.get('/three', headers: {'X-Roles': 'three:foo:baz'});
      print('Response: ${response.body}');
      expect(response, hasStatus(403));

      response =
          await client.get('/three', headers: {'X-Roles': 'three:foz:bar'});
      print('Response: ${response.body}');
      expect(response, hasStatus(403));
    });

    test('three with star', () async {
      var response = await client
          .get('/three-star', headers: {'X-Roles': 'three:foo:bar'});
      print('Response: ${response.body}');
      expect(response, hasStatus(200));
      expect(response, isJson('Hello, world!'));

      response = await client
          .get('/three-star', headers: {'X-Roles': 'three:foz:bar'});
      print('Response: ${response.body}');
      expect(response, hasStatus(200));
      expect(response, isJson('Hello, world!'));

      response = await client
          .get('/three-star', headers: {'X-Roles': 'three:foo:baz'});
      print('Response: ${response.body}');
      expect(response, hasStatus(403));
    });
  });

  test('or', () async {
    var response = await client.get('/or', headers: {'X-Roles': 'admin'});
    print('Response: ${response.body}');
    expect(response, hasStatus(200));
    expect(response, isJson('Hello, world!'));

    response = await client
        .get('/or', headers: {'X-Roles': 'not:specific:enough:i:guess'});
    print('Response: ${response.body}');
    expect(response, hasStatus(403));
  });
}
