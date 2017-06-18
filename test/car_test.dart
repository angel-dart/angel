import 'package:test/test.dart';
import 'models/car.dart';
import 'models/car.orm.g.dart';

final DateTime MILENNIUM = new DateTime.utc(2000, 1, 1);

main() {
  test('to where', () {
    var query = new CarQuery();
    query.where
      ..familyFriendly.equals(true)
      ..recalledAt.lessThanOrEqualTo(MILENNIUM, includeTime: false);
    var whereClause = query.where.toWhereClause();
    print('Where clause: $whereClause');
    expect(whereClause, "WHERE `family_friendly` = 1 AND `recalled_at` <= '00-01-01'");
  });

  test('insert', () async {
    var car = await CarQuery.insert(make: 'Mazda', familyFriendly: false);
    print(car.toJson());
  }, skip: 'Insert not yet implemented');
}
