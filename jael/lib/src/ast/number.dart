import 'dart:math' as math;
import 'package:source_span/source_span.dart';
import 'expression.dart';
import 'token.dart';

class NumberLiteral extends Literal {
  final Token number;
  num _value;

  NumberLiteral(this.number);

  @override
  FileSpan get span => number.span;

  static num parse(String value) {
    var e = value.indexOf('E');
    e != -1 ? e : e = value.indexOf('e');

    if (e == -1) return num.parse(value);

    var plainNumber = num.parse(value.substring(0, e));
    var exp = value.substring(e + 1);
    return plainNumber * math.pow(10, num.parse(exp));
  }

  @override
  compute(scope) {
    return _value ??= parse(number.span.text);
  }
}

class HexLiteral extends Literal {
  final Token hex;
  num _value;

  HexLiteral(this.hex);

  @override
  FileSpan get span => hex.span;

  static num parse(String value) => int.parse(value.substring(2), radix: 16);

  @override
  compute(scope) {
    return _value ??= parse(hex.span.text);
  }
}
