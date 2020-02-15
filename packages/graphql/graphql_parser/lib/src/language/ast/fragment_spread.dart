import '../token.dart';
import 'directive.dart';
import 'node.dart';
import 'package:source_span/source_span.dart';

/// A GraphQL fragment spread.
class FragmentSpreadContext extends Node {
  /// The source tokens.
  final Token ellipsisToken, nameToken;

  /// Any directives affixed to this fragment spread.
  final List<DirectiveContext> directives = [];

  FragmentSpreadContext(this.ellipsisToken, this.nameToken);

  /// The [String] value of the [nameToken].
  String get name => nameToken.text;

  /// Use [ellipsisToken] instead.
  @deprecated
  Token get ELLIPSIS => ellipsisToken;

  /// Use [nameToken] instead.
  @deprecated
  Token get NAME => nameToken;

  @override
  FileSpan get span {
    var out = ellipsisToken.span.expand(nameToken.span);
    if (directives.isEmpty) return out;
    return directives.fold<FileSpan>(out, (o, d) => o.expand(d.span));
  }
}
