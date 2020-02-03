import 'package:source_span/source_span.dart';
import '../token.dart';
import 'node.dart';

/// An alternate name for a field within a [SelectionSet].
class AliasContext extends Node {
  /// The source tokens.
  final Token nameToken1, colonToken, nameToken2;

  AliasContext(this.nameToken1, this.colonToken, this.nameToken2);

  /// Use [nameToken1] instead.
  @deprecated
  Token get NAME1 => nameToken1;

  /// Use [colonToken] instead.
  @deprecated
  Token get COLON => colonToken;

  /// Use [nameToken2] instead.
  @deprecated
  Token get NAME2 => nameToken2;

  /// The aliased name of the value.
  String get alias => nameToken1.text;

  /// The actual name of the value.
  String get name => nameToken2.text;

  @override
  FileSpan get span =>
      nameToken1.span.expand(colonToken.span).expand(nameToken2.span);
}
