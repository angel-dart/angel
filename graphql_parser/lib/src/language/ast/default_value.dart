import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';
import 'node.dart';

/// The default value to be passed to an [ArgumentContext].
class DefaultValueContext extends Node {
  /// The source token.
  final Token equals;

  /// The default value for the argument.
  final InputValueContext value;

  DefaultValueContext(this.equals, this.value);

  /// Use [equals] instead.
  @deprecated
  Token get EQUALS => equals;

  @override
  FileSpan get span => equals.span.expand(value.span);
}
