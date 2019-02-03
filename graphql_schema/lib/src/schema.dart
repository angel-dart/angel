library graphql_schema.src.schema;

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

part 'argument.dart';

part 'enum.dart';

part 'field.dart';

part 'gen.dart';

part 'object_type.dart';

part 'scalar.dart';

part 'type.dart';

part 'union.dart';

part 'validation_result.dart';

/// The schema against which queries, mutations, and subscriptions are executed.
class GraphQLSchema {
  /// The shape which all queries against the backend must take.
  final GraphQLObjectType queryType;

  /// The shape required for any query that changes the state of the backend.
  final GraphQLObjectType mutationType;

  /// A [GraphQLObjectType] describing the form of data sent to real-time subscribers.
  ///
  /// Note that as of August 4th, 2018 (when this text was written), subscriptions are not formalized
  /// in the GraphQL specification. Therefore, any GraphQL implementation can potentially implement
  /// subscriptions in its own way.
  final GraphQLObjectType subscriptionType;

  GraphQLSchema({this.queryType, this.mutationType, this.subscriptionType});
}

/// A shorthand for creating a [GraphQLSchema].
GraphQLSchema graphQLSchema(
        {@required GraphQLObjectType queryType,
        GraphQLObjectType mutationType,
        GraphQLObjectType subscriptionType}) =>
    new GraphQLSchema(
        queryType: queryType,
        mutationType: mutationType,
        subscriptionType: subscriptionType);

/// A default resolver that always returns `null`.
resolveToNull(_, __) => null;

/// An exception that occurs during execution of a GraphQL query.
class GraphQLException implements Exception {
  /// A list of all specific errors, with text representation, that caused this exception.
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

/// One of an arbitrary number of errors that may occur during the execution of a GraphQL query.
///
/// This will almost always be passed to a [GraphQLException], as it is useless alone.
class GraphQLExceptionError {
  /// The reason execution was halted, whether it is a syntax error, or a runtime error, or some other exception.
  final String message;

  /// An optional list of locations within the source text where this error occurred.
  ///
  /// Smart tools can use this information to show end users exactly which part of the errant query
  /// triggered an error.
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

/// Information about a location in source text that caused an error during the execution of a GraphQL query.
///
/// This is analogous to a [SourceLocation] from `package:source_span`.
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

typedef GraphQLType GraphDocumentationTypeProvider();

/// A metadata annotation used to provide documentation to `package:graphql_server`.
class GraphQLDocumentation {
  /// The description of the annotated class, field, or enum value, to be displayed in tools like GraphiQL.
  final String description;

  /// The reason the annotated field or enum value was deprecated, if any.
  final String deprecationReason;

  /// A constant callback that returns an explicit type for the annotated field, rather than having it be assumed
  /// via `dart:mirrors`.
  final GraphDocumentationTypeProvider type;

  /// The name of an explicit type for the annotated field, rather than having it be assumed.
  final Symbol typeName;

  const GraphQLDocumentation(
      {this.description, this.deprecationReason, this.type, this.typeName});
}

/// The canonical instance.
const GraphQLClass graphQLClass = const GraphQLClass._();

/// Signifies that a class should statically generate a [GraphQLSchema].
class GraphQLClass {
  const GraphQLClass._();
}
