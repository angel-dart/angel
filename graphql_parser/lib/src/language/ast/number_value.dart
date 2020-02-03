import 'dart:math' as math;
import 'package:source_span/source_span.dart';
import '../token.dart';
import 'input_value.dart';

/// A GraphQL number literal.
class NumberValueContext extends InputValueContext<num> {
  /// The source token.
  final Token numberToken;

  NumberValueContext(this.numberToken);

  /// The [num] value of the [numberToken].
  num get numberValue {
    var text = numberToken.text;
    if (!text.contains('E') && !text.contains('e')) {
      return num.parse(text);
    } else {
      var split = text.split(text.contains('E') ? 'E' : 'e');
      var base = num.parse(split[0]);
      var exp = num.parse(split[1]);
      return base * math.pow(10, exp);
    }
  }

  /// Use [numberToken] instead.
  @deprecated
  Token get NUMBER => numberToken;

  @override
  FileSpan get span => numberToken.span;

  @override
  num computeValue(Map<String, dynamic> variables) => numberValue;
}
