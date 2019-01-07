library angel_orm_generator.test;

import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/user.dart';
import 'common.dart';

main() {
  QueryExecutor executor;
  Role canPub, canSub;
  User thosakwe;

  setUp(() async {
    executor = await connectToPostgres(['user', 'role', 'user_role']);

    var canPubQuery = new RoleQuery()..values.name = 'can_pub';
    var canSubQuery = new RoleQuery()..values.name = 'can_sub';
    canPub = await canPubQuery.insert(executor);
    canSub = await canSubQuery.insert(executor);

    var thosakweQuery = new UserQuery();
    thosakweQuery.values
      ..username = 'thosakwe'
      ..password = 'Hahahahayoureallythoughtiwasstupidenoughtotypethishere'
      ..email = 'thosakwe AT gmail.com';
    thosakwe = await thosakweQuery.insert(executor);

    // Allow thosakwe to publish...
    var thosakwePubQuery = new RoleUserQuery();
    thosakwePubQuery.values
      ..userId = int.parse(thosakwe.id)
      ..roleId = int.parse(canPub.id);
    await thosakwePubQuery.insert(executor);

    // Allow thosakwe to subscribe...
    var thosakweSubQuery = new RoleUserQuery();
    thosakweSubQuery.values
      ..userId = int.parse(thosakwe.id)
      ..roleId = int.parse(canSub.id);
    await thosakweSubQuery.insert(executor);

    print('\n');
    print('==================================================');
    print('              GOOD STUFF BEGINS HERE              ');
    print('==================================================\n\n');
  });

  Future<User> fetchThosakwe() async {
    var query = new UserQuery()..where.id.equals(int.parse(thosakwe.id));
    return await query.getOne(executor);
  }

  test('fetch roles for user', () async {
    var user = await fetchThosakwe();
    expect(user.roles, hasLength(2));
    expect(user.roles, contains(canPub));
    expect(user.roles, contains(canSub));
  });

  test('fetch users for role', () async {
    for (var role in [canPub, canSub]) {
      var query = new RoleQuery()..where.id.equals(int.parse(role.id));
      var r = await query.getOne(executor);
      expect(r.users, [thosakwe]);
    }
  });
}
