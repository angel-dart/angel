import 'builder.dart';

class JoinOn {
  final SqlExpressionBuilder key;
  final SqlExpressionBuilder value;

  JoinOn(this.key, this.value);
}
