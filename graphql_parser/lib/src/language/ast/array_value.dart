import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';

/// A GraphQL list value literal.
class ListValueContext extends InputValueContext {
  /// The source tokens.
  final Token lBracketToken, rBracketToken;

  /// The child values.
  final List<InputValueContext> values = [];

  ListValueContext(this.lBracketToken, this.rBracketToken);

  /// Use [lBracketToken] instead.
  @deprecated
  Token get LBRACKET => lBracketToken;

  /// Use [rBracketToken] instead.
  @deprecated
  Token get RBRACKET => rBracketToken;

  @override
  FileSpan get span {
    var out =
        values.fold<FileSpan>(lBracketToken.span, (o, v) => o.expand(v.span));
    return out.expand(rBracketToken.span);
  }

  @override
  computeValue(Map<String, dynamic> variables) {
    return values.map((v) => v.computeValue(variables)).toList();
  }
}
