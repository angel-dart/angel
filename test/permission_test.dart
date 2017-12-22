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
    app = new Angel();

    app.use((RequestContext req, res) async {
      // In real life, you'd use auth to check user roles,
      // but in this case, let's just set the user manually
      var xRoles = req.headers.value('X-Roles');

      if (xRoles?.isNotEmpty == true) {
        req.inject('user', new User(req.headers['X-Roles']));
      }

      return true;
    });

    app.chain(new PermissionBuilder.wildcard()).get('/', 'Hello, world!');
    app.chain(new Permission('foo')).get('/one', 'Hello, world!');
    app.chain(new Permission('two:foo')).get('/two', 'Hello, world!');
    app.chain(new Permission('two:*')).get('/two-star', 'Hello, world!');
    app.chain(new Permission('three:foo:bar')).get('/three', 'Hello, world!');
    app
        .chain(new Permission('three:*:bar'))
        .get('/three-star', 'Hello, world!');

    app
        .chain(new PermissionBuilder('super')
            .add('specific')
            .add('permission')
            .allowAll()
            .or(new PermissionBuilder('admin')))
        .get('/or', 'Hello, world!');

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
