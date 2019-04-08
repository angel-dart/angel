import 'dart:async';
import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/unorthodox.dart';

edgeCaseTests(FutureOr<QueryExecutor> Function() createExecutor,
    {FutureOr<void> Function(QueryExecutor) close}) {
  QueryExecutor executor;
  close ??= (_) => null;

  setUp(() async {
    executor = await createExecutor();
  });

  tearDown(() => close(executor));

  test('can create object with no id', () async {
    var query = UnorthodoxQuery()..values.name = 'Hey';
    var model = await query.insert(executor);
    expect(model, Unorthodox(name: 'Hey'));
  });

  group('relations on non-model', () {
    Unorthodox unorthodox;

    setUp(() async {
      var query = UnorthodoxQuery()..values.name = 'Hey';
      unorthodox = await query.insert(executor);
    });

    test('belongs to', () async {
      var query = WeirdJoinQuery()..values.joinName = unorthodox.name;
      var model = await query.insert(executor);
      print(model.toJson());
      expect(model.id, isNotNull); // Postgres should set this.
      expect(model.unorthodox, unorthodox);
    });

    group('layered', () {
      WeirdJoin weirdJoin;
      Song girlBlue;

      setUp(() async {
        var wjQuery = WeirdJoinQuery()..values.joinName = unorthodox.name;
        weirdJoin = await wjQuery.insert(executor);

        var gbQuery = SongQuery()
          ..values.weirdJoinId = weirdJoin.id
          ..values.title = 'Girl Blue';
        girlBlue = await gbQuery.insert(executor);
      });

      test('has one', () async {
        var query = WeirdJoinQuery()..where.id.equals(weirdJoin.id);
        var wj = await query.getOne(executor);
        print(wj.toJson());
        expect(wj.song, girlBlue);
      });

      test('has many', () async {
        var numbas = <Numba>[];

        for (int i = 0; i < 15; i++) {
          var query = NumbaQuery()
            ..values.parent = weirdJoin.id
            ..values.i = i;
          var model = await query.insert(executor);
          numbas.add(model);
        }

        var query = WeirdJoinQuery()..where.id.equals(weirdJoin.id);
        var wj = await query.getOne(executor);
        print(wj.toJson());
        expect(wj.numbas, numbas);
      });

      test('many to many', () async {
        var fooQuery = FooQuery()..values.bar = 'baz';
        var fooBar = await fooQuery.insert(executor).then((foo) => foo.bar);
        var pivotQuery = FooPivotQuery()
          ..values.weirdJoinId = weirdJoin.id
          ..values.fooBar = fooBar;
        await pivotQuery.insert(executor);
        fooQuery = FooQuery()..where.bar.equals('baz');

        var foo = await fooQuery.getOne(executor);
        print(foo.toJson());
        print(weirdJoin.toJson());
        expect(foo.weirdJoins[0].id, weirdJoin.id);
      });
    });
  });
}
