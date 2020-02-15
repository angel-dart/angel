import 'package:source_span/source_span.dart';
import 'token_type.dart';

class Token {
  final TokenType type;
  final String text;
  FileSpan span;

  Token(this.type, this.text, [this.span]);

  @override
  String toString() {
    if (span == null) {
      return "'$text' -> $type";
    } else {
      return "(${span.start.line}:${span.start.column}) '$text' -> $type";
    }
  }
}
