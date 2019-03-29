import 'package:graphql_parser/graphql_parser.dart';

Parser parse(String text) => new Parser(scan(text));
