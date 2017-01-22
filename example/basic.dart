import 'dart:async';
import 'package:graphql_parser/src/language/language.dart';

Stream<String> input() async* {
  yield '''
{
  project(name: "GraphQL") {
    tagline
  }
}
  '''.trim();
}

main() async {
  var lexer = new Lexer(), parser = new Parser();
  await input().transform(lexer).forEach(print);
}
