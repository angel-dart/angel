import 'package:graphql_parser/graphql_parser.dart';

Parser parse(String text) => Parser(scan(text));
