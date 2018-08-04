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
  'variables': predicate((v) => v == null || v is Map),
});

RequestHandler graphQLHttp(GraphQL graphQl) {
  return (req, res) async {
    try {
      if (req.headers.contentType?.mimeType == graphQlContentType.mimeType) {
        var text = utf8.decode(await req.lazyOriginalBuffer());
        return {
          'data': await graphQl.parseAndExecute(text, sourceUrl: 'input')
        };
      } else if (req.headers.contentType?.mimeType == 'application/json') {
        if (await validate(graphQlPostBody)(req, res)) {
          var text = req.body['query'] as String;
          var operationName = req.body['operation_name'] as String;
          var variables = req.body['variables'] as Map;
          return {
            'data': await graphQl.parseAndExecute(
              text,
              sourceUrl: 'input',
              operationName: operationName,
              variableValues: foldToStringDynamic(variables),
            ),
          };
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
    } catch (e) {
      return new GraphQLException.fromMessage(e.toString()).toJson();
    }
  };
}
