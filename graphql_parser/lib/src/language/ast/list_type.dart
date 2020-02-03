import '../token.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';
import 'type.dart';

/// Represents a type that holds a list of another type.
class ListTypeContext extends Node {
  /// The source tokens.
  final Token lBracketToken, rBracketToken;

  /// The inner type.
  final TypeContext innerType;

  ListTypeContext(this.lBracketToken, this.innerType, this.rBracketToken);

  /// Use [innerType] instead.
  @deprecated
  TypeContext get type => innerType;

  /// Use [lBracketToken] instead.
  @deprecated
  Token get LBRACKET => lBracketToken;

  /// Use [rBracketToken] instead.
  @deprecated
  Token get RBRACKET => rBracketToken;

  @override
  FileSpan get span =>
      lBracketToken.span.expand(innerType.span).expand(rBracketToken.span);
}
