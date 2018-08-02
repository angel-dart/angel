library graphql_schema.src.schema;

import 'dart:async';
import 'package:meta/meta.dart';
part 'argument.dart';
part 'field.dart';
part 'gen.dart';
part 'object_type.dart';
part 'scalar.dart';
part 'type.dart';
part 'validation_result.dart';

class GraphQLSchema {
  final GraphQLObjectType query;
  final GraphQLObjectType mutation;

  GraphQLSchema({this.query, this.mutation});
}

GraphQLSchema graphQLSchema(
        {@required GraphQLObjectType query, GraphQLObjectType mutation}) =>
    new GraphQLSchema(query: query, mutation: mutation);
