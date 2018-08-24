import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';

main() {

}

@orm
abstract class Company extends Model {
  String get name;

  bool get isFortune500;
}

@orm
abstract class _Employee extends Model {
  @belongsTo
  Company get company;

  String get firstName;

  String get lastName;

  double get salary;

  bool get isFortune500Employee => company.isFortune500;
}
