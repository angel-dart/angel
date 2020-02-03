import 'node.dart';

/// Represents a value in GraphQL.
abstract class InputValueContext<T> extends Node {
  /// Computes the value, relative to some set of [variables].
  T computeValue(Map<String, dynamic> variables);
}
