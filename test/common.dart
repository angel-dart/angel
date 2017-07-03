import 'package:graphql_parser/graphql_parser.dart';
import 'package:matcher/matcher.dart';

Parser parse(String text) => new Parser(scan(text));

Matcher equalsParsed(value) => new _EqualsParsed(value);

class _EqualsParsed extends Matcher {
  final value;

  _EqualsParsed(this.value);

  @override
  Description describe(Description description)
  => description.add('equals $value when parsed as a GraphQL value');

  @override
  bool matches(String item, Map matchState) {
   var p = parse(item);
   var v = p.parseValue();
   return equals(value).matches(v.value, matchState);
  }
}