import 'package:source_span/source_span.dart';
import '../token.dart';
import 'node.dart';

/// An alternate name for a field within a [SelectionSet].
class AliasContext extends Node {
  /// The source tokens.
  final Token name1, colon, name2;

  AliasContext(this.name1, this.colon, this.name2);

  /// Use [name1] instead.
  @deprecated
  Token get NAME1 => name1;

  /// Use [colon] instead.
  @deprecated
  Token get COLON => colon;

  /// Use [name2] instead.
  @deprecated
  Token get NAME2 => name2;

  /// The aliased name of the value.
  String get alias => name1.text;

  /// The actual name of the value.
  String get name => name2.text;

  @override
  FileSpan get span => name1.span.expand(colon.span).expand(name2.span);
}
