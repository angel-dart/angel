import 'dart:async';
import 'package:graphql_parser/src/language/language.dart';

Stream<String> input() async* {
  yield '''
{
  project(name: "GraphQL") {
    tagline
  }
}
  '''
      .trim();
}

main() {
  var lexer = new Lexer(), parser = new Parser();
  var stream = input().transform(lexer).asBroadcastStream();
  stream
    ..forEach(print)
    ..pipe(parser);
  parser.onNode.forEach(print);
}
