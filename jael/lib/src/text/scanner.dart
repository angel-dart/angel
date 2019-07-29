import 'dart:collection';
import 'package:charcode/ascii.dart';
import 'package:string_scanner/string_scanner.dart';
import '../ast/ast.dart';

final RegExp _whitespace = RegExp(r'[ \n\r\t]+');

final RegExp _id =
    RegExp(r'@?(([A-Za-z][A-Za-z0-9_]*-)*([A-Za-z][A-Za-z0-9_]*))');
final RegExp _string1 = RegExp(
    r"'((\\(['\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^'\\]))*'");
final RegExp _string2 = RegExp(
    r'"((\\(["\\/bfnrt]|(u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])))|([^"\\]))*"');

Scanner scan(String text, {sourceUrl, bool asDSX = false}) =>
    _Scanner(text, sourceUrl)..scan(asDSX: asDSX);

abstract class Scanner {
  List<JaelError> get errors;

  List<Token> get tokens;
}

final RegExp _htmlComment = RegExp(r'<!--[^$]*-->');

final Map<Pattern, TokenType> _expressionPatterns = {
//final Map<Pattern, TokenType> _htmlPatterns = {
  '{{': TokenType.lDoubleCurly,
  '{{-': TokenType.lDoubleCurly,

  //
  _htmlComment: TokenType.htmlComment,
  '!DOCTYPE': TokenType.doctype,
  '!doctype': TokenType.doctype,
  '<': TokenType.lt,
  '>': TokenType.gt,
  '/': TokenType.slash,
  '=': TokenType.equals,
  '!=': TokenType.nequ,
  _string1: TokenType.string,
  _string2: TokenType.string,
  _id: TokenType.id,
//};

//final Map<Pattern, TokenType> _expressionPatterns = {
  '}}': TokenType.rDoubleCurly,

  // Keywords
  'new': TokenType.$new,

  // Misc.
  '*': TokenType.asterisk,
  ':': TokenType.colon,
  ',': TokenType.comma,
  '.': TokenType.dot,
  '??': TokenType.elvis,
  '?.': TokenType.elvis_dot,
  '=': TokenType.equals,
  '!': TokenType.exclamation,
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
  RegExp(r'-?[0-9]+(\.[0-9]+)?([Ee][0-9]+)?'): TokenType.number,
  RegExp(r'0x[A-Fa-f0-9]+'): TokenType.hex,
  _string1: TokenType.string,
  _string2: TokenType.string,
  _id: TokenType.id,
};

class _Scanner implements Scanner {
  final List<JaelError> errors = [];
  final List<Token> tokens = [];
  _ScannerState state = _ScannerState.html;
  final Queue<String> openTags = Queue();

  SpanScanner _scanner;

  _Scanner(String text, sourceUrl) {
    _scanner = SpanScanner(text, sourceUrl: sourceUrl);
  }

  void scan({bool asDSX = false}) {
    while (!_scanner.isDone) {
      if (state == _ScannerState.html) {
        scanHtml(asDSX);
      } else if (state == _ScannerState.freeText) {
        // Just keep parsing until we hit "</"
        var start = _scanner.state, end = start;

        while (!_scanner.isDone) {
          // Skip through comments
          if (_scanner.scan(_htmlComment)) continue;

          // Break on {{ or {
          if (_scanner.matches(asDSX ? '{' : '{{')) {
            state = _ScannerState.html;
            //_scanner.position--;
            break;
          }

          var ch = _scanner.readChar();

          if (ch == $lt) {
            // && !_scanner.isDone) {
            if (_scanner.matches('/')) {
              // If we reached "</", backtrack and break into HTML
              openTags.removeFirst();
              _scanner.position--;
              state = _ScannerState.html;
              break;
            } else if (_scanner.matches(_id)) {
              // Also break when we reach <foo.
              //
              // HOWEVER, that is also JavaScript. So we must
              // only break in this case when the current tag is NOT "script".
              var shouldBreak =
                  (openTags.isEmpty || openTags.first != 'script');

              if (!shouldBreak) {
                // Try to see if we are closing a script tag
                var replay = _scanner.state;
                _scanner
                  ..readChar()
                  ..scan(_whitespace);
                //print(_scanner.emptySpan.highlight());

                if (_scanner.matches(_id)) {
                  //print(_scanner.lastMatch[0]);
                  shouldBreak = _scanner.lastMatch[0] == 'script';
                  _scanner.position--;
                }

                if (!shouldBreak) {
                  _scanner.state = replay;
                }
              }

              if (shouldBreak) {
                openTags.removeFirst();
                _scanner.position--;
                state = _ScannerState.html;
                break;
              }
            }
          }

          // Otherwise, just add to the "buffer"
          end = _scanner.state;
        }

        var span = _scanner.spanFrom(start, end);

        if (span.text.isNotEmpty) {
          tokens.add(Token(TokenType.text, span, null));
        }
      }
    }
  }

  void scanHtml(bool asDSX) {
    var brackets = Queue<Token>();

    do {
      // Only continue if we find a left bracket
      if (true) {
        // || _scanner.matches('<') || _scanner.matches('{{')) {
        var potential = <Token>[];

        while (true) {
          // Scan whitespace
          _scanner.scan(_whitespace);

          _expressionPatterns.forEach((pattern, type) {
            if (_scanner.matches(pattern)) {
              potential.add(Token(type, _scanner.lastSpan, _scanner.lastMatch));
            }
          });

          potential.sort((a, b) => b.span.length.compareTo(a.span.length));

          if (potential.isEmpty) break;

          var token = potential.first;
          tokens.add(token);

          _scanner.scan(token.span.text);

          if (token.type == TokenType.lt) {
            brackets.addFirst(token);

            // Try to see if we are at a tag.
            var replay = _scanner.state;
            _scanner.scan(_whitespace);

            if (_scanner.matches(_id)) {
              openTags.addFirst(_scanner.lastMatch[0]);
            } else {
              _scanner.state = replay;
            }
          } else if (token.type == TokenType.slash) {
            // Only push if we're at </foo
            if (brackets.isNotEmpty && brackets.first.type == TokenType.lt) {
              brackets
                ..removeFirst()
                ..addFirst(token);
            }
          } else if (token.type == TokenType.gt) {
            // Only pop the bracket if we're at foo>, </foo> or foo/>
            if (brackets.isNotEmpty && brackets.first.type == TokenType.slash) {
              // </foo>
              brackets.removeFirst();

              // Now, ONLY continue parsing HTML if the next character is '<'.
              var replay = _scanner.state;
              _scanner.scan(_whitespace);

              if (!_scanner.matches('<')) {
                _scanner.state = replay;
                state = _ScannerState.freeText;
                break;
              }
            }
            //else if (_scanner.matches('>')) brackets.removeFirst();
            else if (brackets.isNotEmpty &&
                brackets.first.type == TokenType.lt) {
              // We're at foo>, try to parse text?
              brackets.removeFirst();

              var replay = _scanner.state;
              _scanner.scan(_whitespace);

              if (!_scanner.matches('<')) {
                _scanner.state = replay;
                state = _ScannerState.freeText;
                break;
              }
            }
          } else if (token.type ==
              (asDSX ? TokenType.rCurly : TokenType.rDoubleCurly)) {
            state = _ScannerState.freeText;
            break;
          }

          potential.clear();
        }
      }
    } while (brackets.isNotEmpty && !_scanner.isDone);

    state = _ScannerState.freeText;
  }
}

enum _ScannerState { html, freeText }
