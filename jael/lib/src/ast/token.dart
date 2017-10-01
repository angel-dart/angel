import 'package:source_span/source_span.dart';

class Token {
  final TokenType type;
  final FileSpan span;

  Token(this.type, this.span);

  @override
  String toString() {
    return '${span.start.toolString}: "${span.text}" => $type';
  }
}

enum TokenType {
  /*
   * HTML
   */
  doctype,
  htmlComment,
  lt,
  gt,
  slash,
  equals,
  id,
  script_tag,
  text,

  // Keywords
  $new,

  /*
   * Expression
   */
  lBracket,
  rBracket,
  doubleCurlyL,
  doubleCurlyR,
  lCurly,
  rCurly,
  lParen,
  rParen,
  asterisk,
  colon,
  comma,
  dot,
  percent,
  plus,
  minus,
  elvis,
  elvis_dot,
  lte,
  gte,
  equ,
  nequ,
  number,
  hex,
  string,
  question,
}