import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_security/hooks.dart' as hooks;
import 'package:angel_test/angel_test.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

main() {
  Angel app;
  TestClient client;

  setUp(() async {
    app = new Angel()
      ..lazyParseBodies = true
      ..before.add((RequestContext req, res) async {
        var xUser = req.headers.value('X-User');
        if (xUser != null)
          req.inject('user',
              new User(id: xUser, roles: xUser == 'John' ? ['foo:bar'] : []));
        return true;
      });

    app
      ..use('/user_data', new UserDataService())
      ..use('/artists', new ArtistService())
      ..use('/roled', new RoledService());

    app.service('user_data')
      ..beforeIndexed.listen(hooks.queryWithCurrentUser())
      ..beforeCreated.listen(hooks.hashPassword());

    app.service('artists')
      ..beforeIndexed.listen(hooks.restrictToAuthenticated())
      ..beforeRead.listen(hooks.restrictToOwner())
      ..beforeCreated.listen(hooks.associateCurrentUser());

    app.service('roled')
      ..beforeIndexed.listen(new Permission('foo:*').toHook())
      ..beforeRead.listen(new Permission('foo:*').toHook(owner: true));

    app.fatalErrorStream.listen((e) {
      print('Fatal: ${e.error}');
      print(e.stack);
    });

    client = await connectTo(app);
  });

  tearDown(() => client.close());

  group('associateCurrentUser', () {
    test('fail', () async {
      try {
        var response = await client.service('artists').create({'foo': 'bar'});
        print(response);
        throw new StateError('Creating without userId bad request');
      } catch (e) {
        print(e);
        expect(e, new isInstanceOf<AngelHttpException>());
        var err = e as AngelHttpException;
        expect(err.statusCode, equals(403));
      }
    });

    test('succeed', () async {
      var response = await client
          .post('/artists', headers: {'X-User': 'John'}, body: {'foo': 'bar'});
      print('Response: ${response.body}');
      print('Status: ${response.statusCode}');
      expect(response, allOf(hasStatus(201), isJson({'foo': 'bar'})));
    });
  });

  group('queryWithCurrentUser', () {
    test('fail', () async {
      try {
        var response = await client.service('user_data').index();
        print(response);
        throw new StateError('Indexing without user forbidden');
      } catch (e) {
        print(e);
        expect(e, new isInstanceOf<AngelHttpException>());
        var err = e as AngelHttpException;
        expect(err.statusCode, equals(403));
      }
    });

    test('succeed', () async {
      var response = await client.get('user_data', headers: {'X-User': 'John'});
      print('Response: ${response.body}');
      expect(response, allOf(hasStatus(200), isJson(['foo', 'bar'])));
    });
  });

  test('hashPassword', () async {
    var response = await client
        .service('user_data')
        .create({'username': 'foo', 'password': 'jdoe1'});
    print('Response: ${response}');
    expect(response, equals({'foo': 'bar'}));
  });

  group('restrictToAuthenticated', () {
    test('fail', () async {
      try {
        var response = await client.service('artists').index();
        print(response);
        throw new StateError('Indexing without user forbidden');
      } catch (e) {
        print(e);
        expect(e, new isInstanceOf<AngelHttpException>());
        var err = e as AngelHttpException;
        expect(err.statusCode, equals(403));
      }
    });

    test('succeed', () async {
      var response = await client.get('/artists', headers: {'X-User': 'John'});
      print('Response: ${response.body}');
      expect(
          response,
          allOf(
              hasStatus(200),
              isJson([
                {
                  "id": "king_of_pop",
                  "userId": "John",
                  "name": "Michael Jackson"
                },
                {"id": "raymond", "userId": "Bob", "name": "Usher"}
              ])));
    });
  });

  group('restrictToOwner', () {
    test('fail', () async {
      try {
        var response = await client.service('artists').read('king_of_pop');
        print(response);
        throw new StateError('Reading without owner forbidden');
      } catch (e) {
        print(e);
        expect(e, new isInstanceOf<AngelHttpException>());
        var err = e as AngelHttpException;
        expect(err.statusCode, equals(401));
      }
    });

    test('succeed', () async {
      var response =
          await client.get('/artists/king_of_pop', headers: {'X-User': 'John'});
      print('Response: ${response.body}');
      expect(
          response,
          allOf(
              hasStatus(200),
              isJson({
                "id": "king_of_pop",
                "userId": "John",
                "name": "Michael Jackson"
              })));
    });
  });

  group('permission restrict', () {
    test('fail', () async {
      try {
        var response = await client.service('roled').index();
        print(response);
        throw new StateError('Reading without roles forbidden');
      } catch (e) {
        print(e);
        expect(e, new isInstanceOf<AngelHttpException>());
        var err = e as AngelHttpException;
        expect(err.statusCode, equals(403));
      }
    });

    test('succeed', () async {
      var response =
          await client.get('/roled/king_of_pop', headers: {'X-User': 'John'});
      print('Response: ${response.body}');
      expect(
          response,
          allOf(
              hasStatus(200),
              isJson({
                "id": "king_of_pop",
                "userId": "John",
                "name": "Michael Jackson"
              })));
    });

    test('owner', () async {
      var response =
          await client.get('/roled/raymond', headers: {'X-User': 'Bob'});
      print('Response: ${response.body}');
      expect(
          response,
          allOf(hasStatus(200),
              isJson({"id": "raymond", "userId": "Bob", "name": "Usher"})));
    });
  });
}

class User {
  String id;
  List<String> roles;
  User({this.id, this.roles: const []});
}

class UserDataService extends Service {
  static const Map<String, List> _data = const {
    'John': const ['foo', 'bar']
  };

  @override
  index([Map params]) async {
    print('Params: $params');
    if (params?.containsKey('query') != true)
      throw new AngelHttpException.badRequest(message: 'query required');

    String name = params['query']['userId']?.toString();

    if (!_data.containsKey(name))
      throw new AngelHttpException.notFound(
          message: "No data found for user '$name'.");

    return _data[name];
  }

  @override
  create(data, [Map params]) async {
    if (data is! Map || !data.containsKey('password'))
      throw new AngelHttpException.badRequest(message: 'Required password!');

    var expected =
        new String.fromCharCodes(sha256.convert('jdoe1'.codeUnits).bytes);

    if (data['password'] != (expected))
      throw new AngelHttpException.conflict(message: 'Passwords do not match.');
    return {'foo': 'bar'};
  }
}

class ArtistService extends Service {
  static const List<Artist> _ARTISTS = const [_MICHAEL_JACKSON, _USHER];

  @override
  index([params]) async => _ARTISTS;

  @override
  read(id, [params]) async => _ARTISTS.firstWhere((a) => a.id == id);

  @override
  create(data, [params]) async {
    if (data is! Map || !data.containsKey('userId'))
      throw new AngelHttpException.badRequest(message: 'Required userId');

    return {'foo': 'bar'};
  }
}

class Artist {
  final String id, userId, name;
  const Artist({this.id, this.userId, this.name});
}

const Artist _USHER = const Artist(id: 'raymond', userId: 'Bob', name: 'Usher');
const Artist _MICHAEL_JACKSON =
    const Artist(id: 'king_of_pop', userId: 'John', name: 'Michael Jackson');

class RoledService extends Service {
  @override
  index([params]) {
    return ['foo'];
  }

  @override
  read(id, [params]) async =>
      ArtistService._ARTISTS.firstWhere((a) => a.id == id);
}
