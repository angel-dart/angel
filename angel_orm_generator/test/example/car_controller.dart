import 'dart:async';
import 'package:angel_framework/angel_framework.dart';
import 'package:postgres/postgres.dart';
import '../models/car.dart';
import '../models/car.orm.g.dart';

@Expose('/api/cars')
class CarController extends Controller {
  @Expose('/luxury')
  Stream<Car> getLuxuryCars(PostgreSQLConnection connection) {
    var query = new CarQuery();
    query.where
      ..familyFriendly.equals(false)
      ..createdAt.year.greaterThanOrEqualTo(2014)
      ..make.isIn(['Ferrari', 'Lamborghini', 'Mustang', 'Lexus']);
    return query.get(connection);
  }
}
