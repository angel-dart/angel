import 'node.dart';

abstract class ConstantContext<T> extends Node {
  T get value;
  T computeValue(Map<String, dynamic> variables) => value;
}

/// Use [ConstantContext] instead. This class remains solely for backwards compatibility.
@deprecated
abstract class ValueContext<T> extends ConstantContext<T> {
  T get value;
}
