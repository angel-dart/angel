import 'package:jael/src/ast/token.dart';
import 'package:jael/src/text/scanner.dart';
import 'package:test/test.dart';
import 'common.dart';

main() {
  test('plain html', () {
    var tokens = scan('<img src="foo.png" />', sourceUrl: 'test.jael').tokens;
    tokens.forEach(print);

    expect(tokens, hasLength(7));
    expect(tokens[0], isToken(TokenType.lt));
    expect(tokens[1], isToken(TokenType.id, 'img'));
    expect(tokens[2], isToken(TokenType.id, 'src'));
    expect(tokens[3], isToken(TokenType.equals));
    expect(tokens[4], isToken(TokenType.string, '"foo.png"'));
    expect(tokens[5], isToken(TokenType.slash));
    expect(tokens[6], isToken(TokenType.gt));
  });

  test('single quotes', () {
    var tokens = scan('<p>It\'s lit</p>', sourceUrl: 'test.jael').tokens;
    tokens.forEach(print);

    expect(tokens, hasLength(8));
    expect(tokens[0], isToken(TokenType.lt));
    expect(tokens[1], isToken(TokenType.id, 'p'));
    expect(tokens[2], isToken(TokenType.gt));
    expect(tokens[3], isToken(TokenType.text, 'It\'s lit'));
    expect(tokens[4], isToken(TokenType.lt));
    expect(tokens[5], isToken(TokenType.slash));
    expect(tokens[6], isToken(TokenType.id, 'p'));
    expect(tokens[7], isToken(TokenType.gt));
  });

  test('text node', () {
    var tokens = scan('<p>Hello\nworld</p>', sourceUrl: 'test.jael').tokens;
    tokens.forEach(print);

    expect(tokens, hasLength(8));
    expect(tokens[0], isToken(TokenType.lt));
    expect(tokens[1], isToken(TokenType.id, 'p'));
    expect(tokens[2], isToken(TokenType.gt));
    expect(tokens[3], isToken(TokenType.text, 'Hello\nworld'));
    expect(tokens[4], isToken(TokenType.lt));
    expect(tokens[5], isToken(TokenType.slash));
    expect(tokens[6], isToken(TokenType.id, 'p'));
    expect(tokens[7], isToken(TokenType.gt));
  });

  test('mixed', () {
    var tokens = scan('<ul number=1 + 2>three{{four > five.six}}</ul>',
            sourceUrl: 'test.jael')
        .tokens;
    tokens.forEach(print);

    expect(tokens, hasLength(20));
    expect(tokens[0], isToken(TokenType.lt));
    expect(tokens[1], isToken(TokenType.id, 'ul'));
    expect(tokens[2], isToken(TokenType.id, 'number'));
    expect(tokens[3], isToken(TokenType.equals));
    expect(tokens[4], isToken(TokenType.number, '1'));
    expect(tokens[5], isToken(TokenType.plus));
    expect(tokens[6], isToken(TokenType.number, '2'));
    expect(tokens[7], isToken(TokenType.gt));
    expect(tokens[8], isToken(TokenType.text, 'three'));
    expect(tokens[9], isToken(TokenType.lDoubleCurly));
    expect(tokens[10], isToken(TokenType.id, 'four'));
    expect(tokens[11], isToken(TokenType.gt));
    expect(tokens[12], isToken(TokenType.id, 'five'));
    expect(tokens[13], isToken(TokenType.dot));
    expect(tokens[14], isToken(TokenType.id, 'six'));
    expect(tokens[15], isToken(TokenType.rDoubleCurly));
    expect(tokens[16], isToken(TokenType.lt));
    expect(tokens[17], isToken(TokenType.slash));
    expect(tokens[18], isToken(TokenType.id, 'ul'));
    expect(tokens[19], isToken(TokenType.gt));
  });

  test('script tag interpolation', () {
    var tokens = scan(
      '''
<script aria-label="script">
  window.alert('a string');
</script>
'''
          .trim(),
      sourceUrl: 'test.jael',
    ).tokens;
    tokens.forEach(print);

    expect(tokens, hasLength(11));
    expect(tokens[0], isToken(TokenType.lt));
    expect(tokens[1], isToken(TokenType.id, 'script'));
    expect(tokens[2], isToken(TokenType.id, 'aria-label'));
    expect(tokens[3], isToken(TokenType.equals));
    expect(tokens[4], isToken(TokenType.string));
    expect(tokens[5], isToken(TokenType.gt));
    expect(
        tokens[6], isToken(TokenType.text, "\n  window.alert('a string');\n"));
    expect(tokens[7], isToken(TokenType.lt));
    expect(tokens[8], isToken(TokenType.slash));
    expect(tokens[9], isToken(TokenType.id, 'script'));
    expect(tokens[10], isToken(TokenType.gt));
  });
}
