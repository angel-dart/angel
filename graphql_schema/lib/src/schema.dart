library graphql_schema.src.schema;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

part 'argument.dart';

part 'enum.dart';

part 'field.dart';

part 'gen.dart';

part 'object_type.dart';

part 'scalar.dart';

part 'type.dart';

part 'validation_result.dart';

class GraphQLSchema {
  final GraphQLObjectType query;
  final GraphQLObjectType mutation;
  final GraphQLObjectType subscription;

  GraphQLSchema({this.query, this.mutation, this.subscription});
}

GraphQLSchema graphQLSchema(
        {@required GraphQLObjectType query,
        GraphQLObjectType mutation,
        GraphQLObjectType subscription}) =>
    new GraphQLSchema(
        query: query, mutation: mutation, subscription: subscription);

/// A default resolver that always returns `null`.
resolveToNull(_, __) => null;

/// An error that occurs during execution of a GraphQL query.
class GraphQLException implements Exception {
  final List<GraphQLExceptionError> errors;

  GraphQLException(this.errors);

  factory GraphQLException.fromMessage(String message) {
    return new GraphQLException([
      new GraphQLExceptionError(message),
    ]);
  }

  factory GraphQLException.fromSourceSpan(String message, FileSpan span) {
    return new GraphQLException([
      new GraphQLExceptionError(
        message,
        locations: [
          new GraphExceptionErrorLocation.fromSourceLocation(span.start),
        ],
      ),
    ]);
  }

  Map<String, List<Map<String, dynamic>>> toJson() {
    return {
      'errors': errors.map((e) => e.toJson()).toList(),
    };
  }
}

class GraphQLExceptionError {
  final String message;
  final List<GraphExceptionErrorLocation> locations;

  GraphQLExceptionError(this.message, {this.locations: const []});

  Map<String, dynamic> toJson() {
    var out = <String, dynamic>{'message': message};
    if (locations?.isNotEmpty == true) {
      out['locations'] = locations.map((l) => l.toJson()).toList();
    }
    return out;
  }
}

class GraphExceptionErrorLocation {
  final int line;
  final int column;

  GraphExceptionErrorLocation(this.line, this.column);

  factory GraphExceptionErrorLocation.fromSourceLocation(
      SourceLocation location) {
    return new GraphExceptionErrorLocation(location.line, location.column);
  }

  Map<String, int> toJson() {
    return {'line': line, 'column': column};
  }
}

typedef GraphQLType _GraphDocumentationTypeProvider();

/// A metadata annotation used to provide documentation to `package:graphql_server`.
class GraphQLDocumentation {
  final String description;
  final String deprecationReason;
  final _GraphDocumentationTypeProvider type;

  const GraphQLDocumentation(
      {this.description, this.deprecationReason, GraphQLType this.type()});
}
