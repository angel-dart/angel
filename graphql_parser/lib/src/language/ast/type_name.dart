import 'node.dart';
import 'package:source_span/source_span.dart';
import '../token.dart';

/// The name of a GraphQL type.
class TypeNameContext extends Node {
  /// The source token.
  final Token nameToken;

  TypeNameContext(this.nameToken);

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  /// The [String] value of the [nameToken].
  String get name => nameToken.text;

  @override
  FileSpan get span => nameToken.span;
}
