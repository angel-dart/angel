import 'package:source_span/source_span.dart';
import '../token.dart';
import 'list_type.dart';
import 'node.dart';
import 'type_name.dart';

/// A GraphQL type node.
class TypeContext extends Node {
  /// A source token, present in a nullable type literal.
  final Token exclamationToken;

  /// The name of the referenced type.
  final TypeNameContext typeName;

  /// A list type that is being referenced.
  final ListTypeContext listType;

  /// Whether the type is nullable.
  bool get isNullable => exclamationToken == null;

  TypeContext(this.typeName, this.listType, [this.exclamationToken]) {
    assert(typeName != null || listType != null);
  }

  /// Use [exclamationToken] instead.
  @deprecated
  Token get EXCLAMATION => exclamationToken;

  @override
  FileSpan get span {
    var out = typeName?.span ?? listType.span;
    return exclamationToken != null ? out.expand(exclamationToken.span) : out;
  }
}
