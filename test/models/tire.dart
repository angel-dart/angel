library angel_test.test.models.tire;

import 'package:angel_framework/common.dart';
import 'package:angel_serialize/angel_serialize.dart';
part 'tire.g.dart';

@serializable
class _Tire extends Model {
  int size;
}
