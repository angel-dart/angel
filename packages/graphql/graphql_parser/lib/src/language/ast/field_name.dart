import 'package:source_span/source_span.dart';
import '../token.dart';
import 'alias.dart';
import 'node.dart';

/// The name of a GraphQL [FieldContext], which may or may not be [alias]ed.
class FieldNameContext extends Node {
  /// The source token.
  final Token nameToken;

  /// An (optional) alias for the field.
  final AliasContext alias;

  FieldNameContext(this.nameToken, [this.alias]) {
    assert(nameToken != null || alias != null);
  }

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  /// The [String] value of the [nameToken], if any.
  String get name => nameToken?.text;

  @override
  FileSpan get span => alias?.span ?? nameToken.span;
}
