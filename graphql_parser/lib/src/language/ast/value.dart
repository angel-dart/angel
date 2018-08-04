import 'node.dart';

abstract class ValueContext<T> extends Node {
  T get value;
}
