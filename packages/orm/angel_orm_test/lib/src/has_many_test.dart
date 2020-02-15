import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/tree.dart';

hasManyTests(FutureOr<QueryExecutor> Function() createExecutor,
    {FutureOr<void> Function(QueryExecutor) close}) {
  QueryExecutor executor;
  Tree appleTree;
  int treeId;
  close ??= (_) => null;

  setUp(() async {
    var query = new TreeQuery()..values.rings = 10;

    executor = await createExecutor();
    appleTree = await query.insert(executor);
    treeId = int.parse(appleTree.id);
  });

  tearDown(() => close(executor));

  test('list is empty if there is nothing', () {
    expect(appleTree.rings, 10);
    expect(appleTree.fruits, isEmpty);
  });

  group('mutations', () {
    Fruit apple, banana;

    void verify(Tree tree) {
      print(tree.fruits.map(FruitSerializer.toMap).toList());
      expect(tree.fruits, hasLength(2));
      expect(tree.fruits[0].commonName, apple.commonName);
      expect(tree.fruits[1].commonName, banana.commonName);
    }

    setUp(() async {
      var appleQuery = new FruitQuery()
        ..values.treeId = treeId
        ..values.commonName = 'Apple';

      var bananaQuery = new FruitQuery()
        ..values.treeId = treeId
        ..values.commonName = 'Banana';

      apple = await appleQuery.insert(executor);
      banana = await bananaQuery.insert(executor);
    });

    test('can fetch any children', () async {
      var query = new TreeQuery()..where.id.equals(treeId);
      var tree = await query.getOne(executor);
      verify(tree);
    });

    test('sets on update', () async {
      var tq = new TreeQuery()
        ..where.id.equals(treeId)
        ..values.rings = 24;
      var tree = await tq.updateOne(executor);
      verify(tree);
      expect(tree.rings, 24);
    });

    test('sets on delete', () async {
      var tq = new TreeQuery()..where.id.equals(treeId);
      var tree = await tq.deleteOne(executor);
      verify(tree);
    });

    test('returns empty on false subquery', () async {
      var tq = new TreeQuery()
        ..where.id.equals(treeId)
        ..fruits.where.commonName.equals('Kiwi');
      var tree = await tq.getOne(executor);
      expect(tree.fruits, isEmpty);
    });
  });
}
