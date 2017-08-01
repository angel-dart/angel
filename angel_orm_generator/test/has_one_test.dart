/// Tests for @hasOne...
library angel_orm_generator.test.has_one_test;

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'models/foot.orm.g.dart';
import 'models/leg.dart';
import 'models/leg.orm.g.dart';
import 'common.dart';

main() {
  PostgreSQLConnection connection;
  Leg originalLeg;

  setUp(() async {
    connection = await connectToPostgres(['leg', 'foot']);
    originalLeg = await LegQuery.insert(connection, name: 'Left');
  });

  test('sets to null if no child', () async {
    var leg = await LegQuery.getOne(int.parse(originalLeg.id), connection);
    expect(leg.name, originalLeg.name);
    expect(leg.id, originalLeg.id);
    expect(leg.foot, isNull);
  });

  test('can fetch one foot', () async {
    var foot = await FootQuery.insert(connection,
        legId: int.parse(originalLeg.id), nToes: 5);
    var leg = await LegQuery.getOne(int.parse(originalLeg.id), connection);
    expect(leg.name, originalLeg.name);
    expect(leg.id, originalLeg.id);
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });

  test('only fetches one foot even if there are multiple', () async {
    var foot = await FootQuery.insert(connection,
        legId: int.parse(originalLeg.id), nToes: 5);
    await FootQuery.insert(connection,
        legId: int.parse(originalLeg.id), nToes: 24);
    var leg = await LegQuery.getOne(int.parse(originalLeg.id), connection);
    expect(leg.name, originalLeg.name);
    expect(leg.id, originalLeg.id);
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });

  test('sets foot on update', () async {
    var foot = await FootQuery.insert(connection,
        legId: int.parse(originalLeg.id), nToes: 5);
    var leg = await LegQuery.updateLeg(
        connection, originalLeg.clone()..name = 'Right');
    print(leg.toJson());
    expect(leg.name, 'Right');
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });

  test('sets foot on delete', () async {
    var foot = await FootQuery.insert(connection,
        legId: int.parse(originalLeg.id), nToes: 5);
    var leg = await LegQuery.deleteOne(int.parse(originalLeg.id), connection);
    print(leg.toJson());
    expect(leg.name, originalLeg.name);
    expect(leg.foot, isNotNull);
    expect(leg.foot.id, foot.id);
    expect(leg.foot.nToes, foot.nToes);
  });
}
