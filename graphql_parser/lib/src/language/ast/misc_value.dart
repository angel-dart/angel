import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';
import 'node.dart';

/// A GraphQL `null` literal.
class NullValueContext extends InputValueContext<Null> {
  /// The source token.
  final Token nullToken;

  NullValueContext(this.nullToken);

  /// Use [nullToken] instead.
  @deprecated
  Token get NULL => nullToken;

  @override
  FileSpan get span => nullToken.span;

  @override
  Null computeValue(Map<String, dynamic> variables) => null;
}

/// A GraphQL enumeration literal.
class EnumValueContext extends InputValueContext<String> {
  /// The source token.
  final Token nameToken;

  EnumValueContext(this.nameToken);

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  @override
  FileSpan get span => nameToken.span;

  @override
  String computeValue(Map<String, dynamic> variables) => nameToken.span.text;
}

/// A GraphQL object literal.
class ObjectValueContext extends InputValueContext<Map<String, dynamic>> {
  /// The source tokens.
  final Token lBraceToken, rBraceToken;

  /// The fields in the object.
  final List<ObjectFieldContext> fields;

  ObjectValueContext(this.lBraceToken, this.fields, this.rBraceToken);

  /// Use [lBraceToken] instead.
  Token get LBRACE => lBraceToken;

  /// Use [rBraceToken] instead.
  @deprecated
  Token get RBRACE => rBraceToken;

  @override
  FileSpan get span {
    var left = lBraceToken.span;

    for (var field in fields) {
      left = left.expand(field.span);
    }

    return left.expand(rBraceToken.span);
  }

  @override
  Map<String, dynamic> computeValue(Map<String, dynamic> variables) {
    if (fields.isEmpty) {
      return <String, dynamic>{};
    } else {
      return fields.fold<Map<String, dynamic>>(<String, dynamic>{},
          (map, field) {
        return map
          ..[field.nameToken.text] = field.value.computeValue(variables);
      });
    }
  }
}

/// A field within an [ObjectValueContext].
class ObjectFieldContext extends Node {
  /// The source tokens.
  final Token nameToken, colonToken;

  /// The associated value.
  final InputValueContext value;

  ObjectFieldContext(this.nameToken, this.colonToken, this.value);

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  /// Use [colonToken] instead.
  @deprecated
  Token get COLON => colonToken;

  @override
  FileSpan get span =>
      nameToken.span.expand(colonToken.span).expand(value.span);
}
