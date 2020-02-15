import 'package:test/test.dart';

import 'common.dart';

main() {
  test('variables', () {
    expect(r'$a', isVariable('a'));
    expect(r'$abc', isVariable('abc'));
    expect(r'$abc123', isVariable('abc123'));
    expect(r'$_', isVariable('_'));
    expect(r'$___', isVariable('___'));
    expect(r'$_123', isVariable('_123'));
  });

  test('exceptions', () {
    var throwsSyntaxError = predicate((x) {
      var parser = parse(x.toString())..parseVariable();
      return parser.errors.isNotEmpty;
    }, 'fails to parse variable');

    expect(r'$', throwsSyntaxError);
  });
}

Matcher isVariable(String name) => _IsVariable(name);

class _IsVariable extends Matcher {
  final String name;

  _IsVariable(this.name);

  @override
  Description describe(Description description) {
    return description.add('parses as a variable named "$name"');
  }

  @override
  bool matches(item, Map matchState) {
    var p = parse(item.toString());
    var v = p.parseVariable();
    return equals(name).matches(v?.name, matchState);
  }
}
