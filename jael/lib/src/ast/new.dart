import 'dart:mirrors';
import 'package:source_span/source_span.dart';
import 'call.dart';
import 'expression.dart';
import 'member.dart';
import 'token.dart';

class NewExpression extends Expression {
  final Token $new;
  final Call call;

  NewExpression(this.$new, this.call);

  @override
  FileSpan get span => $new.span.expand(call.span);

  @override
  compute(scope) {
    var targetType = call.target.compute(scope);
    var positional = call.computePositional(scope);
    var named = call.computeNamed(scope);
    var name = '';

    if (call.target is MemberExpression) {
      name = (call.target as MemberExpression).name.name;
    }

    return reflectClass(targetType as Type)
        .newInstance(Symbol(name), positional, named)
        .reflectee;
  }
}
