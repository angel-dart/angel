import 'dart:async';
import 'package:graphql_parser/src/language/language.dart';

Stream<String> input() async* {
  yield 'true';
}

main() async {
  var lexer = new Lexer(), parser = new Parser();
  input().transform(lexer).pipe(parser);
  await parser.onBooleanValue.forEach(print);
}
