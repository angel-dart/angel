import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'token.dart';

class Conditional extends Expression {
  final Expression condition, ifTrue, ifFalse;
  final Token question, colon;

  Conditional(
      this.condition, this.question, this.ifTrue, this.colon, this.ifFalse);

  @override
  FileSpan get span {
    return condition.span
        .expand(question.span)
        .expand(ifTrue.span)
        .expand(colon.span)
        .expand(ifFalse.span);
  }

  @override
  compute(scope) {
    var v = condition.compute(scope) as bool;

    if (scope.resolve('!strict!')?.value == false) {
      v = v == true;
    }

    return v ? ifTrue.compute(scope) : ifFalse.compute(scope);
  }
}
