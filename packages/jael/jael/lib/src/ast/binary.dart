import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'token.dart';

class BinaryExpression extends Expression {
  final Expression left, right;
  final Token operator;

  BinaryExpression(this.left, this.operator, this.right);

  @override
  compute(scope) {
    var l = left.compute(scope), r = right.compute(scope);

    switch (operator?.type) {
      case TokenType.asterisk:
        return l * r;
      case TokenType.slash:
        return l / r;
      case TokenType.plus:
        if (l is String || r is String) return l.toString() + r.toString();
        return l + r;
      case TokenType.minus:
        return l - r;
      case TokenType.lt:
        return l < r;
      case TokenType.gt:
        return l > r;
      case TokenType.lte:
        return l <= r;
      case TokenType.gte:
        return l >= r;
      case TokenType.equ:
        return l == r;
      case TokenType.nequ:
        return l != r;
      case TokenType.elvis:
        return l ?? r;
      default:
        throw UnsupportedError(
            'Unsupported binary operator: "${operator?.span?.text ?? "<null>"}".');
    }
  }

  @override
  FileSpan get span => left.span.expand(operator.span).expand(right.span);
}
