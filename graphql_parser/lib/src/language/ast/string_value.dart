import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';
import '../syntax_error.dart';
import '../token.dart';
import 'value.dart';

class StringValueContext extends ValueContext {
  final Token STRING;

  StringValueContext(this.STRING);

  @override
  FileSpan get span => STRING.span;

  String get stringValue {
    var text = STRING.text.substring(1, STRING.text.length - 1);
    var codeUnits = text.codeUnits;
    var buf = new StringBuffer();

    for (int i = 0; i < codeUnits.length; i++) {
      var ch = codeUnits[i];

      if (ch == $backslash) {
        if (i < codeUnits.length - 5 && codeUnits[i + 1] == $u) {
          var c1 = codeUnits[i += 2],
              c2 = codeUnits[++i],
              c3 = codeUnits[++i],
              c4 = codeUnits[++i];
          var hexString = new String.fromCharCodes([c1, c2, c3, c4]);
          var hexNumber = int.parse(hexString, radix: 16);
          buf.write(new String.fromCharCode(hexNumber));
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
        } else
          throw new SyntaxError(
              'Unexpected "\\" in string literal.', span);
      } else {
        buf.writeCharCode(ch);
      }
    }

    return buf.toString();
  }

  @override
  get value => stringValue;
}
