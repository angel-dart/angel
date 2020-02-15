import 'package:source_span/source_span.dart';
import 'element.dart';
import 'expression.dart';
import 'token.dart';

class Interpolation extends ElementChild {
  final Token doubleCurlyL, doubleCurlyR;
  final Expression expression;

  Interpolation(this.doubleCurlyL, this.expression, this.doubleCurlyR);

  bool get isRaw => doubleCurlyL.span.text.endsWith('-');

  @override
  FileSpan get span {
    return doubleCurlyL.span.expand(expression.span).expand(doubleCurlyR.span);
  }
}
