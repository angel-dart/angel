import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';

/// A GraphQL list value literal.
class ListValueContext extends InputValueContext {
  /// The source tokens.
  final Token lBracket, rBracket;

  /// The child values.
  final List<InputValueContext> values = [];

  ListValueContext(this.lBracket, this.rBracket);

  /// Use [lBracket] instead.
  @deprecated
  Token get LBRACKET => lBracket;

  /// Use [rBracket] instead.
  @deprecated
  Token get RBRACKET => rBracket;

  @override
  FileSpan get span {
    var out = values.fold<FileSpan>(lBracket.span, (o, v) => o.expand(v.span));
    return out.expand(rBracket.span);
  }

  @override
  computeValue(Map<String, dynamic> variables) {
    return values.map((v) => v.computeValue(variables)).toList();
  }
}
