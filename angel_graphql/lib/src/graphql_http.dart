import 'dart:io';

import 'package:angel_framework/angel_framework.dart';
import 'package:angel_validate/server.dart';
import 'package:dart2_constant/convert.dart';
import 'package:graphql_parser/graphql_parser.dart';
import 'package:graphql_schema/graphql_schema.dart';
import 'package:graphql_server/graphql_server.dart';

final ContentType graphQlContentType =
    new ContentType('application', 'graphql');

final Validator graphQlPostBody = new Validator({
  'query*': isNonEmptyString,
  'operation_name': isNonEmptyString,
  'variables': predicate((v) => v == null || v is String || v is Map),
});

/// A [RequestHandler] that serves a spec-compliant GraphQL backend.
///
/// Follows the guidelines listed here:
/// https://graphql.org/learn/serving-over-http/
RequestHandler graphQLHttp(GraphQL graphQL) {
  return (req, res) async {
    var globalVariables = <String, dynamic>{
      '__requestctx': req,
      '__responsectx': res,
    };

    executeMap(Map map) async {
      var text = req.body['query'] as String;
      var operationName = req.body['operation_name'] as String;
      var variables = req.body['variables'];

      if (variables is String) {
        variables = json.decode(variables as String);
      }

      return {
        'data': await graphQL.parseAndExecute(
          text,
          sourceUrl: 'input',
          operationName: operationName,
          variableValues: foldToStringDynamic(variables as Map),
          globalVariables: globalVariables,
        ),
      };
    }

    try {
      if (req.method == 'GET') {
        if (await validateQuery(graphQlPostBody)(req, res)) {
          return await executeMap(req.query);
        }
      } else if (req.method == 'POST') {
        if (req.headers.contentType?.mimeType == graphQlContentType.mimeType) {
          var text = utf8.decode(await req.lazyOriginalBuffer());
          return {
            'data': await graphQL.parseAndExecute(
              text,
              sourceUrl: 'input',
              globalVariables: globalVariables,
            ),
          };
        } else if (req.headers.contentType?.mimeType == 'application/json') {
          if (await validate(graphQlPostBody)(req, res)) {
            return await executeMap(req.body);
          }
        } else {
          throw new AngelHttpException.badRequest();
        }
      } else {
        throw new AngelHttpException.badRequest();
      }
    } on ValidationException catch (e) {
      var errors = <GraphQLExceptionError>[
        new GraphQLExceptionError(e.message)
      ];

      errors
          .addAll(e.errors.map((ee) => new GraphQLExceptionError(ee)).toList());
      return new GraphQLException(errors).toJson();
    } on AngelHttpException catch (e) {
      var errors = <GraphQLExceptionError>[
        new GraphQLExceptionError(e.message)
      ];

      errors
          .addAll(e.errors.map((ee) => new GraphQLExceptionError(ee)).toList());
      return new GraphQLException(errors).toJson();
    } on SyntaxError catch (e) {
      return new GraphQLException.fromSourceSpan(e.message, e.span);
    } on GraphQLException catch (e) {
      return e.toJson();
    } catch (e, st) {
      if (req.app?.logger != null) {
        req.app.logger.severe(
            'An error occurred while processing GraphQL query at ${req.uri}.',
            e,
            st);
      }

      return new GraphQLException.fromMessage(e.toString()).toJson();
    }
  };
}
