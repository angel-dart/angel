import 'dart:async';
import 'package:graphql_parser/src/language/language.dart';

final String INPUT = '''
{
  project(name: "GraphQL") {
    tagline
  }
}
  '''.trim();

main() {
  var tokens = scan(INPUT);
  var parser = new Parser(tokens);
}
