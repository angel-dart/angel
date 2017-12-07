library angel_orm_generator.test.models.order;

import 'package:angel_model/angel_model.dart';
import 'package:angel_orm/angel_orm.dart';
import 'package:angel_serialize/angel_serialize.dart';
import 'customer.dart';
part 'order.g.dart';

@orm
@serializable
class _Order extends Model {
  @CanJoin(Customer, 'id')
  int customerId;
  int employeeId;
  DateTime orderDate;
  int shipperId;
}