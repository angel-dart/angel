import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';

import '../syntax_error.dart';
import '../token.dart';
import 'input_value.dart';

class StringValueContext extends InputValueContext<String> {
  final Token STRING;
  final bool isBlockString;

  StringValueContext(this.STRING, {this.isBlockString: false});

  @override
  FileSpan get span => STRING.span;

  String get stringValue {
    String text;

    if (!isBlockString) {
      text = STRING.text.substring(1, STRING.text.length - 1);
    } else {
      text = STRING.text.substring(3, STRING.text.length - 3).trim();
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
