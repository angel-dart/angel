import 'package:charcode/charcode.dart';
import 'package:source_span/source_span.dart';
import 'package:symbol_table/symbol_table.dart';
import '../ast/ast.dart';
import 'expression.dart';
import 'token.dart';

class StringLiteral extends Literal {
  final Token string;
  final String value;

  StringLiteral(this.string, this.value);

  static String parseValue(Token string) {
    var text = string.span.text.substring(1, string.span.text.length - 1);
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
          throw JaelError(JaelErrorSeverity.error,
              'Unexpected "\\" in string literal.', string.span);
        }
      } else {
        buf.writeCharCode(ch);
      }
    }

    return buf.toString();
  }

  @override
  compute(SymbolTable scope) {
    return value;
  }

  @override
  FileSpan get span => string.span;
}
