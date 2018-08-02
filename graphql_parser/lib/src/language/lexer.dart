import 'package:string_scanner/string_scanner.dart';
import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';

final RegExp _comment = new RegExp(r'#[^\n]*');
final RegExp _whitespace = new RegExp('[ \t\n\r]+');
final RegExp _boolean = new RegExp(r'true|false');
final RegExp _number = new RegExp(r'-?[0-9]+(\.[0-9]+)?(E|e(\+|-)?[0-9]+)?');
final RegExp _string = new RegExp(
    r'"((\\(["\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^"\\]))*"');
final RegExp _name = new RegExp(r'[_A-Za-z][_0-9A-Za-z]*');

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
  'fragment': TokenType.FRAGMENT,
  'mutation': TokenType.MUTATION,
  'on': TokenType.ON,
  'query': TokenType.QUERY,
  _boolean: TokenType.BOOLEAN,
  _number: TokenType.NUMBER,
  _string: TokenType.STRING,
  _name: TokenType.NAME
};

List<Token> scan(String text) {
  List<Token> out = [];
  var scanner = new SpanScanner(text);

  while (!scanner.isDone) {
    List<Token> potential = [];

    if (scanner.scan(_comment) || scanner.scan(_whitespace)) continue;

    for (var pattern in _patterns.keys) {
      if (scanner.matches(pattern)) {
        potential.add(new Token(
            _patterns[pattern], scanner.lastMatch[0], scanner.lastSpan));
      }
    }

    if (potential.isEmpty) {
      var ch = new String.fromCharCode(scanner.readChar());
      throw new SyntaxError(
          "Unexpected token '$ch'.", scanner.state.line, scanner.state.column);
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
