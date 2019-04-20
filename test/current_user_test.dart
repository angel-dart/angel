import 'dart:async';

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_security/angel_security.dart';
import 'package:angel_security/hooks.dart' as hooks;
import 'package:angel_test/angel_test.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'pretty_logging.dart';

void main() {
  Angel app;
  TestClient client;

  setUp(() async {
    var logger = Logger.detached('hooks_test')..onRecord.listen(prettyLog);
    app = Angel(logger: logger);
    client = await connectTo(app);

    HookedService<String, T, Service<String, T>> serve<T>(String path,
        T Function(Map) encoder, Map<String, dynamic> Function(T) decoder) {
      var inner = MapService();
      var mapped = inner.map(encoder, decoder);
      return app.use<String, T, Service<String, T>>(path, mapped);
    }

    var userService =
        serve<User>('/api/users', User.fromMap, (u) => u.toJson());
    var houseService =
        serve<House>('/api/houses', House.fromMap, (h) => h.toJson());

    // Seed things up.
    var pSherman = await userService.create(User('0', 'P Sherman'));
    await houseService.create(House('0', pSherman.id, '42 Wallaby Way'));
    await houseService.create(House('1', pSherman.id, 'Finding Nemo'));
    await houseService
        .create(House('1', '4', 'Should Not Appear for P. Sherman'));

    // Inject a user depending on the authorization header.
    app.container.registerFactory<Future<User>>((container) async {
      var req = container.make<RequestContext>();
      var authValue =
          req.headers.value('authorization')?.replaceAll('Bearer', '')?.trim();
      if (authValue == null)
        throw AngelHttpException.badRequest(
            message: 'Missing "authorization".');
      var user = await userService.read(authValue).catchError((_) => null);
      if (user == null)
        throw AngelHttpException.notAuthenticated(
            message: 'Invalid "authorization" ($authValue).');
      return user;
    });

    // ACCESS CONTROL:

    // A user can only see their own houses.
    houseService.beforeIndexed.listen(hooks.queryWithCurrentUser<String, User>(
      as: 'owner_id',
      getId: (user) => user.id,
    ));

    // A house is associated with the current user.
    houseService.beforeCreated
        .listen(hooks.associateCurrentUser<String, House, User>(
      getId: (user) => user.id,
      assignUserId: (id, house) => house.withOwner(id),
    ));
  });

  tearDown(() async {
    app.logger.clearListeners();
    await app.close();
    unawaited(client.close());
  });

  test('query with current user', () async {
    client.authToken = '0';
    var houseService = client.service('/api/houses');
    expect(await houseService.index(), [
      {'id': '0', 'owner_id': '0', 'address': '42 Wallaby Way'},
      {'id': '1', 'owner_id': '0', 'address': 'Finding Nemo'}
    ]);
  });

  test('associate current user', () async {
    client.authToken = '0';
    var houseService = client.service('/api/houses');
    expect(
        await houseService.create({'address': 'Hello'}),
        allOf(
          containsPair('address', 'Hello'),
          containsPair('owner_id', '0'),
        ));
  });
}

class User {
  final String id;
  final String name;

  User(this.id, this.name);

  static User fromMap(Map map) =>
      User(map['id'] as String, map['name'] as String);

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}

class House {
  final String id;
  final String ownerId;
  final String address;

  House(this.id, this.ownerId, this.address);

  static House fromMap(Map map) => House(
      map['id'] as String, map['owner_id'] as String, map['address'] as String);

  House withOwner(String newOwnerId) {
    return House(id, newOwnerId, address);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'owner_id': ownerId, 'address': address};
  }
}
