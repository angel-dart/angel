import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';
import 'node.dart';

/// The default value to be passed to an [ArgumentContext].
class DefaultValueContext extends Node {
  /// The source token.
  final Token equalsToken;

  /// The default value for the argument.
  final InputValueContext value;

  DefaultValueContext(this.equalsToken, this.value);

  /// Use [equalsToken] instead.
  @deprecated
  Token get EQUALS => equalsToken;

  @override
  FileSpan get span => equalsToken.span.expand(value.span);
}
