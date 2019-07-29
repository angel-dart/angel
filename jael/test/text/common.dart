import 'package:matcher/matcher.dart';
import 'package:jael/src/ast/token.dart';

Matcher isToken(TokenType type, [String text]) => _IsToken(type, text);

class _IsToken extends Matcher {
  final TokenType type;
  final String text;

  _IsToken(this.type, [this.text]);

  @override
  Description describe(Description description) {
    if (text == null) return description.add('has type $type');
    return description.add('has type $type and text "$text"');
  }

  @override
  bool matches(item, Map matchState) {
    return item is Token &&
        item.type == type &&
        (text == null || item.span.text == text);
  }
}
