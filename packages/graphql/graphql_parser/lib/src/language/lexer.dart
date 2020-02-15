import 'package:string_scanner/string_scanner.dart';

import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';

final RegExp _comment = RegExp(r'#[^\n]*');
final RegExp _whitespace = RegExp('[ \t\n\r]+');
// final RegExp _boolean = RegExp(r'true|false');
final RegExp _number = RegExp(r'-?[0-9]+(\.[0-9]+)?(E|e(\+|-)?[0-9]+)?');
final RegExp _string = RegExp(
    r'"((\\(["\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^"\\]))*"');
final RegExp _blockString = RegExp(r'"""(([^"])|(\\"""))*"""');
final RegExp _name = RegExp(r'[_A-Za-z][_0-9A-Za-z]*');

final Map<Pattern, TokenType> _patterns = {
  '@': TokenType.ARROBA,
  ':': TokenType.COLON,
  ',': TokenType.COMMA,
  r'$': TokenType.DOLLAR,
  '...': TokenType.ELLIPSIS,
  '=': TokenType.EQUALS,
  '!': TokenType.EXCLAMATION,
  '{': TokenType.LBRACE,
  '}': TokenType.RBRACE,
  '[': TokenType.LBRACKET,
  ']': TokenType.RBRACKET,
  '(': TokenType.LPAREN,
  ')': TokenType.RPAREN,
  // 'fragment': TokenType.FRAGMENT,
  // 'mutation': TokenType.MUTATION,
  // 'subscription': TokenType.SUBSCRIPTION,
  // 'on': TokenType.ON,
  // 'query': TokenType.QUERY,
  // 'null': TokenType.NULL,
  // _boolean: TokenType.BOOLEAN,
  _number: TokenType.NUMBER,
  _string: TokenType.STRING,
  _blockString: TokenType.BLOCK_STRING,
  _name: TokenType.NAME
};

List<Token> scan(String text, {sourceUrl}) {
  List<Token> out = [];
  var scanner = SpanScanner(text, sourceUrl: sourceUrl);

  while (!scanner.isDone) {
    List<Token> potential = [];

    if (scanner.scan(_comment) ||
        scanner.scan(_whitespace) ||
        scanner.scan(',') ||
        scanner.scan('\ufeff')) continue;

    for (var pattern in _patterns.keys) {
      if (scanner.matches(pattern)) {
        potential.add(
            Token(_patterns[pattern], scanner.lastMatch[0], scanner.lastSpan));
      }
    }

    if (potential.isEmpty) {
      var ch = String.fromCharCode(scanner.readChar());
      throw SyntaxError("Unexpected token '$ch'.", scanner.emptySpan);
    } else {
      // Choose longest token
      potential.sort((a, b) => b.text.length.compareTo(a.text.length));
      var chosen = potential.first;
      out.add(chosen);
      scanner.scan(chosen.text);
    }
  }

  return out;
}
