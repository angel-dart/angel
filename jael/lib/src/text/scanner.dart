import 'package:string_scanner/string_scanner.dart';
import '../ast/ast.dart';

final RegExp _whitespace = new RegExp(r'[ \n\r\t]+');

final RegExp _string1 = new RegExp(
    r"'((\\(['\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^'\\]))*'");
final RegExp _string2 = new RegExp(
    r'"((\\(["\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^"\\]))*"');

Scanner scan(String text, {sourceUrl}) => new _Scanner(text, sourceUrl)..scan();

abstract class Scanner {
  List<JaelError> get errors;

  List<Token> get tokens;
}

final Map<Pattern, TokenType> _htmlPatterns = {
  '{{': TokenType.doubleCurlyL,
  '{{-': TokenType.doubleCurlyL,

  //
  new RegExp(r'<!--[^$]*-->'): TokenType.htmlComment,
  '!DOCTYPE': TokenType.doctype,
  '!doctype': TokenType.doctype,
  '<': TokenType.lt,
  '>': TokenType.gt,
  '/': TokenType.slash,
  '=': TokenType.equals,
  '!=': TokenType.nequ,
  _string1: TokenType.string,
  _string2: TokenType.string,
  new RegExp(r'<script[^>]*>[^$]*</script>'): TokenType.script_tag,
  new RegExp(r'([A-Za-z][A-Za-z0-9]*-)*([A-Za-z][A-Za-z0-9]*)'): TokenType.id,
};

final Map<Pattern, TokenType> _expressionPatterns = {
  '}}': TokenType.doubleCurlyR,

  // Keywords
  'new': TokenType.$new,

  // Misc.
  '*': TokenType.asterisk,
  ':': TokenType.colon,
  ',': TokenType.comma,
  '.': TokenType.dot,
  '=': TokenType.equals,
  '-': TokenType.minus,
  '%': TokenType.percent,
  '+': TokenType.plus,
  '[': TokenType.lBracket,
  ']': TokenType.rBracket,
  '{': TokenType.lCurly,
  '}': TokenType.rCurly,
  '(': TokenType.lParen,
  ')': TokenType.rParen,
  '/': TokenType.slash,
  '<': TokenType.lt,
  '<=': TokenType.lte,
  '>': TokenType.gt,
  '>=': TokenType.gte,
  '==': TokenType.equ,
  '!=': TokenType.nequ,
  '=': TokenType.equals,
  new RegExp(r'-?[0-9]+(\.[0-9]+)?([Ee][0-9]+)?'): TokenType.number,
  new RegExp(r'0x[A-Fa-f0-9]+'): TokenType.hex,
  _string1: TokenType.string,
  _string2: TokenType.string,
  new RegExp('[A-Za-z_\\\$][A-Za-z0-9_\\\$]*'): TokenType.id,
};

class _Scanner implements Scanner {
  final List<JaelError> errors = [];
  final List<Token> tokens = [];

  SpanScanner _scanner;

  _Scanner(String text, sourceUrl) {
    _scanner = new SpanScanner(text, sourceUrl: sourceUrl);
  }

  Token _scanFrom(Map<Pattern, TokenType> patterns,
      [LineScannerState textStart]) {
    var potential = <Token>[];

    patterns.forEach((pattern, type) {
      if (_scanner.matches(pattern))
        potential.add(new Token(type, _scanner.lastSpan));
    });

    if (potential.isEmpty) return null;

    if (textStart != null) {
      var span = _scanner.spanFrom(textStart);
      tokens.add(new Token(TokenType.text, span));
    }

    potential.sort((a, b) => b.span.length.compareTo(a.span.length));

    var token = potential.first;
    tokens.add(token);

    _scanner.scan(token.span.text);

    return token;
  }

  void scan() {
    while (!_scanner.isDone) scanHtmlTokens();
  }

  void scanHtmlTokens() {
    LineScannerState textStart;

    while (!_scanner.isDone) {
      var state = _scanner.state;

      // Skip whitespace conditionally
      if (textStart == null) {
        _scanner.scan(_whitespace);
      }

      var lastToken = _scanFrom(_htmlPatterns, textStart);

      if (lastToken?.type == TokenType.equals || lastToken?.type == TokenType.nequ) {
        textStart = null;
        scanExpressionTokens();
        return;
      } else if (lastToken?.type == TokenType.doubleCurlyL) {
        textStart = null;
        scanExpressionTokens(true);
        return;
      } else if (lastToken?.type == TokenType.id &&
          tokens.length >= 2 &&
          tokens[tokens.length - 2].type == TokenType.gt) {
        // Fold in the ID into a text node...
        tokens.removeLast();
        textStart = state;
      } else if (lastToken?.type == TokenType.id &&
          tokens.length >= 2 &&
          tokens[tokens.length - 2].type == TokenType.text) {
        // Append the ID into the old text node
        tokens.removeLast();
        tokens.removeLast();

        // Not sure how, but the following logic seems to occur
        // automatically:
        //
        //var textToken = tokens.removeLast();
        //var newSpan = textToken.span.expand(lastToken.span);
        //tokens.add(new Token(TokenType.text, newSpan));
      } else if (lastToken != null) {
        textStart = null;
      } else if (!_scanner.isDone ?? lastToken == null) {
        textStart ??= state;
        _scanner.readChar();
      }
    }

    if (textStart != null) {
      var span = _scanner.spanFrom(textStart);
      tokens.add(new Token(TokenType.text, span));
    }
  }

  void scanExpressionTokens([bool allowGt = false]) {
    Token lastToken;

    do {
      _scanner.scan(_whitespace);
      lastToken = _scanFrom(_expressionPatterns);
    } while (!_scanner.isDone &&
        lastToken != null &&
        lastToken.type != TokenType.doubleCurlyR &&
        (allowGt || lastToken.type != TokenType.gt));
  }
}
