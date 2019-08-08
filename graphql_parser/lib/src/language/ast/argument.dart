import 'package:source_span/source_span.dart';
import '../token.dart';
import 'node.dart';
import 'input_value.dart';

/// An argument passed to a [FieldContext].
class ArgumentContext extends Node {
  /// The source tokens.
  final Token nameToken, colonToken;

  /// The value of the argument.
  final InputValueContext value;

  ArgumentContext(this.nameToken, this.colonToken, this.value);

  /// Use [value] instead.
  @deprecated
  InputValueContext get valueOrVariable => value;

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  /// Use [colonToken] instead.
  @deprecated
  Token get COLON => colonToken;

  /// The name of the argument, as a [String].
  String get name => nameToken.text;

  @override
  FileSpan get span =>
      nameToken.span.expand(colonToken.span).expand(value.span);
}
