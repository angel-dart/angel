import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';

/// A variable reference in GraphQL.
class VariableContext extends InputValueContext<Object> {
  /// The source tokens.
  final Token dollarToken, nameToken;

  VariableContext(this.dollarToken, this.nameToken);

  /// The [String] value of the [nameToken].
  String get name => nameToken.text;

  /// Use [dollarToken] instead.
  @deprecated
  Token get DOLLAR => dollarToken;

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  @override
  FileSpan get span => dollarToken.span.expand(nameToken.span);

  @override
  Object computeValue(Map<String, dynamic> variables) => variables[name];
}
