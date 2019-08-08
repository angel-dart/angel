import 'dart:math' as math;
import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';

class NumberValueContext extends InputValueContext<num> {
  final Token NUMBER;

  NumberValueContext(this.NUMBER);

  num get numberValue {
    var text = NUMBER.text;
    if (!text.contains('E') && !text.contains('e'))
      return num.parse(text);
    else {
      var split = text.split(text.contains('E') ? 'E' : 'e');
      var base = num.parse(split[0]);
      var exp = num.parse(split[1]);
      return base * math.pow(10, exp);
    }
  }

  @override
  FileSpan get span => NUMBER.span;

  @override
  num computeValue(Map<String, dynamic> variables) => numberValue;
}
