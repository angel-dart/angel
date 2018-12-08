/// Tests for @hasOne...
library angel_orm_generator.test.has_one_test;

import 'package:angel_orm/angel_orm.dart';
import 'package:test/test.dart';
import 'models/foot.dart';
import 'models/leg.dart';
import 'common.dart';

main() {
  QueryExecutor executor;
  Leg originalLeg;

  setUp(() async {
    executor = await connectToPostgres(['leg', 'foot']);
    var query = new LegQuery()..values.name = 'Left';
    originalLeg = await query.insert(executor);
  });

  test('sets to null if no child', () async {
    var query = new LegQuery()..where.id.equals(int.parse(originalLeg.id));
    var leg = await query.getOne(executor);
    print(leg.toJson());
    expect(leg.name, originalLeg.name);
    expect(leg.id, originalLeg.id);
    expect(leg.foot, isNull);
  });

  test('can fetch one foot', () async {
    var footQuery = new FootQuery()
      ..values.legId = int.parse(originalLeg.id)
      ..values.nToes = 5;
    var legQuery = new LegQuery()..where.id.equals(int.parse(originalLeg.id));
    var foot = await footQuery.insert(executor);
    var leg = await legQuery.getOne(executor);

    expect(leg.name, originalLeg.name);
    expect(leg.id, originalLeg.id);
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });

  test('only fetches one foot even if there are multiple', () async {
    var footQuery = new FootQuery()
      ..values.legId = int.parse(originalLeg.id)
      ..values.nToes = 24;
    var legQuery = new LegQuery()..where.id.equals(int.parse(originalLeg.id));
    var foot = await footQuery.insert(executor);
    var leg = await legQuery.getOne(executor);
    expect(leg.name, originalLeg.name);
    expect(leg.id, originalLeg.id);
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });

  test('sets foot on update', () async {
    var footQuery = new FootQuery()
      ..values.legId = int.parse(originalLeg.id)
      ..values.nToes = 5;
    var legQuery = new LegQuery()
      ..where.id.equals(int.parse(originalLeg.id))
      ..values.copyFrom(originalLeg.copyWith(name: 'Right'));
    var foot = await footQuery.insert(executor);
    var leg = await legQuery.updateOne(executor);
    print(leg.toJson());
    expect(leg.name, 'Right');
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });

  test('sets foot on delete', () async {
    var footQuery = new FootQuery()
      ..values.legId = int.parse(originalLeg.id)
      ..values.nToes = 5;
    var legQuery = new LegQuery()..where.id.equals(int.parse(originalLeg.id));
    var foot = await footQuery.insert(executor);
    var leg = await legQuery.deleteOne(executor);
    print(leg.toJson());
    expect(leg.name, originalLeg.name);
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });
}
