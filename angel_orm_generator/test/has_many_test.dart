import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'models/fruit.dart';
import 'models/fruit.orm.g.dart';
import 'models/tree.dart';
import 'models/tree.orm.g.dart';
import 'common.dart';

main() {
  PostgreSQLConnection connection;
  Tree appleTree;
  int treeId;

  setUp(() async {
    connection = await connectToPostgres(['tree', 'fruit']);
    appleTree = await TreeQuery.insert(connection, rings: 10);
    treeId = int.parse(appleTree.id);
  });

  test('list is empty if there is nothing', () {
    expect(appleTree.rings, 10);
    expect(appleTree.fruits, isEmpty);
  });

  group('mutations', () {
    Fruit apple, banana;

    void verify(Tree tree) {
      print(tree.fruits.map((f) => f.toJson()).toList());
      expect(tree.fruits, hasLength(2));
      expect(tree.fruits[0].commonName, apple.commonName);
      expect(tree.fruits[1].commonName, banana.commonName);
    }

    setUp(() async {
      apple = await FruitQuery.insert(
        connection,
        treeId: treeId,
        commonName: 'Apple',
      );

      banana = await FruitQuery.insert(
        connection,
        treeId: treeId,
        commonName: 'Banana',
      );
    });

    test('can fetch any children', () async {
      var tree = await TreeQuery.getOne(treeId, connection);
      verify(tree);
    });

    test('sets on update', () async {
      var tq = new TreeQuery()..where.id.equals(treeId);
      var tree = await tq.update(connection, rings: 24).first;
      verify(tree);
      expect(tree.rings, 24);
    });

    test('sets on delete', () async {
      var tq = new TreeQuery()..where.id.equals(treeId);
      var tree = await tq.delete(connection).first;
      verify(tree);
    });
  });
}
