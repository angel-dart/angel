import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';

import '../syntax_error.dart';
import '../token.dart';
import 'input_value.dart';

/// A GraphQL string value literal.
class StringValueContext extends InputValueContext<String> {
  /// The source token.
  final Token stringToken;

  /// Whether this is a block string.
  final bool isBlockString;

  StringValueContext(this.stringToken, {this.isBlockString = false});

  @override
  FileSpan get span => stringToken.span;

  /// Use [stringToken] instead.
  @deprecated
  Token get STRING => stringToken;

  /// The [String] value of the [stringToken].
  String get stringValue {
    String text;

    if (!isBlockString) {
      text = stringToken.text.substring(1, stringToken.text.length - 1);
    } else {
      text = stringToken.text.substring(3, stringToken.text.length - 3).trim();
    }

    var codeUnits = text.codeUnits;
    var buf = StringBuffer();

    for (int i = 0; i < codeUnits.length; i++) {
      var ch = codeUnits[i];

      if (ch == $backslash) {
        if (i < codeUnits.length - 5 && codeUnits[i + 1] == $u) {
          var c1 = codeUnits[i += 2],
              c2 = codeUnits[++i],
              c3 = codeUnits[++i],
              c4 = codeUnits[++i];
          var hexString = String.fromCharCodes([c1, c2, c3, c4]);
          var hexNumber = int.parse(hexString, radix: 16);
          buf.write(String.fromCharCode(hexNumber));
          continue;
        }

        if (i < codeUnits.length - 1) {
          var next = codeUnits[++i];

          switch (next) {
            case $b:
              buf.write('\b');
              break;
            case $f:
              buf.write('\f');
              break;
            case $n:
              buf.writeCharCode($lf);
              break;
            case $r:
              buf.writeCharCode($cr);
              break;
            case $t:
              buf.writeCharCode($tab);
              break;
            default:
              buf.writeCharCode(next);
          }
        } else {
          throw SyntaxError('Unexpected "\\" in string literal.', span);
        }
      } else {
        buf.writeCharCode(ch);
      }
    }

    return buf.toString();
  }

  @override
  String computeValue(Map<String, dynamic> variables) => stringValue;
}
