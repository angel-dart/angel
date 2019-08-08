import 'node.dart';

abstract class InputValueContext<T> extends Node {
  T computeValue(Map<String, dynamic> variables);
}
