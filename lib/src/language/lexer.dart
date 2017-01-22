import 'dart:async';
import 'package:string_scanner/string_scanner.dart';
import 'package:source_span/source_span.dart';
import 'syntax_error.dart';
import 'token.dart';
import 'token_type.dart';

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

class Lexer implements StreamTransformer<String, Token> {
  @override
  Stream<Token> bind(Stream<String> stream) {
    var ctrl = new StreamController<Token>();

    stream.listen((str) {
      var scanner = new StringScanner(str);
      int line = 1, column = 1;

      while (!scanner.isDone) {
        List<Token> potential = [];

        if (scanner.scan(_whitespace)) {
          var text = scanner.lastMatch[0];
          line += '\n'.allMatches(text).length;
          var lastNewLine = text.lastIndexOf('\n');

          if (lastNewLine != -1) {
            int len = text.substring(lastNewLine + 1).length;
            column = 1 + len;
          }

          continue;
        }

        for (var pattern in _patterns.keys) {
          if (scanner.matches(pattern)) {
            potential.add(new Token(_patterns[pattern], scanner.lastMatch[0]));
          }
        }

        if (potential.isEmpty) {
          var ch = new String.fromCharCode(scanner.readChar());
          ctrl.addError(new SyntaxError("Unexpected token '$ch'.", line, column));
        } else {
          // Choose longest token
          potential.sort((a, b) => a.text.length.compareTo(b.text.length));
          var chosen = potential.first;
          var start =
              new SourceLocation(scanner.position, line: line, column: column);
          ctrl.add(chosen);
          scanner.position += chosen.text.length;
          column += chosen.text.length;
          var end =
              new SourceLocation(scanner.position, line: line, column: column);
          chosen.span = new SourceSpan(start, end, chosen.text);
        }
      }
    })
      ..onDone(ctrl.close)
      ..onError(ctrl.addError);

    return ctrl.stream;
  }
}
