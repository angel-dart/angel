import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';

Query findEmployees(Company company) {
  return new Query()
    ..['company_id'] = equals(company.id)
    ..['first_name'] = notNull() & (equals('John'))
    ..['salary'] = greaterThanOrEqual(100000.0);
}

@ORM('api/companies')
class Company extends Model {
  String name;
  bool isFortune500;
}

@orm
class Employee extends Model {
  @belongsTo
  Company company;

  String firstName, lastName;

  double salary;

  bool get isFortune500Employee => company.isFortune500;
}
